import math
from scipy import signal
import numpy as np
import matplotlib.pyplot as plt


def to_signed(x, n):
    """Changes value x into signed n bit integer

    Args:
        x (int): value
        bits (int): number of bits in signed integer
    """
    mask = (1 << n-1)
    x = x ^ mask
    sign = x & mask
    
    return (-1 if sign != 0 else 1) * (x & (mask-1))


class Oscillator:
    def __init__(self, main_clk_freq=50000000, sample_clk_freq=44100, sel=0, output_width=12, counter_width=24):
        self.main_clk_freq = main_clk_freq
        self.sample_clk_freq = sample_clk_freq
        self.sel = sel
        self.output_width = output_width
        self.counter_width = counter_width

        # Calculate number of cycles for each sample
        self.cycles_per_sample = self.main_clk_freq // self.sample_clk_freq

        # Initialize registers
        self.counter = 0
        self.sample_counter = 0

    def wvf_square(self):
        return 0 if self.counter >> (self.counter_width - self.output_width) <= 2 ** (self.output_width - 1) else 2 ** self.output_width - 1

    def wvf_toothsaw(self):
        return self.counter >> (self.counter_width - self.output_width)

    def wvf_sine(self):
        angle = 2 * math.pi * self.counter / (2 ** self.counter_width)
        return int(round((2 ** (self.output_width - 1)) * math.sin(angle)))

    def wvf_triangle(self):
        if self.counter < (2 ** (self.counter_width - 1)):
            return self.counter >> (self.counter_width - self.output_width)
        else:
            return (2 ** self.output_width - 1) - (self.counter >> (self.counter_width - self.output_width))

    def __iter__(self):
        while True:
            if self.sample_counter == 0:
                if self.sel == 0:
                    yield self.wvf_square()
                elif self.sel == 1:
                    yield self.wvf_toothsaw()
                elif self.sel == 2:
                    yield self.wvf_sine()
                elif self.sel == 3:
                    yield self.wvf_triangle()

            # Update counters
            self.counter = (self.counter + self.sample_clk_freq) % (2 ** self.counter_width)
            self.sample_counter = (self.sample_counter + 1) % self.sample_clk_freq


class BiquadFilter:
    def __init__(self, b0, b1, b2, a1, a2):
        self.b0 = b0
        self.b1 = b1
        self.b2 = b2
        self.a1 = a1
        self.a2 = a2

        self.x_n1 = 0
        self.x_n2 = 0
    
        self.y_n  = 0
        self.y_n1 = 0
        self.y_n2 = 0

    
    def tick(self, x_n):
        y_n = self.b0 * x_n + self.b1 * self.x_n1 + self.b2 * self.x_n2  - self.a1 * self.y_n1 - self.a2 * self.y_n2
        self.x_n2 = self.x_n1
        self.x_n1 = x_n
        self.y_n2 = self.y_n1
        self.y_n1 = y_n
        return y_n
    
class EnvelopeGenerator:
    def __init__(self, attack_time, decay_time, sustain_level, release_time, sample_rate):
        self.attack_time = attack_time
        self.decay_time = decay_time
        self.sustain_level = sustain_level
        self.release_time = release_time
        self.sample_rate = sample_rate

        self.attack_samples = int(self.attack_time * self.sample_rate)
        self.decay_samples = int(self.decay_time * self.sample_rate)
        self.release_samples = int(self.release_time * self.sample_rate)

        self.state = "idle"
        self.sample_count = 0
        self.current_level = 0.0

    def trigger(self):
        self.state = "attack"
        self.sample_count = 0

    def tick(self):
        if self.state == "idle":
            self.current_level = 0.0
        elif self.state == "attack":
            if self.sample_count >= self.attack_samples:
                self.state = "decay"
                self.sample_count = 0
            else:
                self.current_level = self.sample_count / self.attack_samples
                self.sample_count += 1
        elif self.state == "decay":
            if self.sample_count >= self.decay_samples:
                self.state = "sustain"
                self.sample_count = 0
            else:
                decay_factor = 1.0 - self.sustain_level
                self.current_level = 1.0 - decay_factor * (self.sample_count / self.decay_samples)
                self.sample_count += 1
        elif self.state == "sustain":
            self.current_level = self.sustain_level
        elif self.state == "release":
            if self.sample_count >= self.release_samples:
                self.state = "idle"
                self.sample_count = 0
            else:
                release_factor = self.sustain_level
                self.current_level = self.sustain_level - release_factor * (self.sample_count / self.release_samples)
                self.sample_count += 1

        return self.current_level

        
def main(sel):
    osc_waveform = []
    filtered_waveform = []
    envelope_waveform_osc = []
    envelope_waveform_fil = []
    
    osc = Oscillator(
        main_clk_freq=50000000,
        sample_clk_freq=44100,
        sel=sel,
        output_width=8,
        counter_width=24
    )
    
    a1 = -0.05042209
    a2 = 0.19971489
    b0 = 1.04882478
    b1 = -0.05042209
    b2 = 0.15089012
    biquad_filter = BiquadFilter(b0, b1, b2, a1, a2)
    
    # Envelope parameters
    attack_time = 0.25
    decay_time = 0.25
    sustain_level = 0.25
    release_time = 0.25
    sample_rate = 200

    # Instantiate the envelope generator
    envelope = EnvelopeGenerator(attack_time, decay_time, sustain_level, release_time, sample_rate)
    
    samples = 1000
    for i, osc_value in enumerate(osc):
        if i >= samples:
            break
        
        # Trigger the envelope at the beginning of each note
        if i % osc.cycles_per_sample == 0:
            envelope.trigger()
        
        osc_value = (osc_value - (2**(osc.output_width-1)))/ (2**(osc.output_width -1))
        
        envelope_value = envelope.tick()
        fil_value = biquad_filter.tick(osc_value)

        osc_waveform.append(osc_value)
        filtered_waveform.append(fil_value)
        envelope_waveform_osc.append(envelope_value * osc_value)
        envelope_waveform_fil.append(envelope_value * fil_value)
        
        if i % 10 == 0:
            print(f"{len(osc_waveform)} {osc_value=} {fil_value=} {envelope_value=}")
        
        
    t = list(range(samples))
    # Plotting
    plt.figure(figsize=(20, 12))
    
    plt.subplot(4, 1, 1)
    plt.plot(t, osc_waveform)
    plt.title('Oscillator Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')

    plt.subplot(4, 1, 2)
    plt.plot(t, filtered_waveform)
    plt.title('Filtered Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')

    plt.subplot(4, 1, 3)
    plt.plot(t, envelope_waveform_osc)
    plt.title('Envelope * Oscillator Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')
    
    plt.subplot(4, 1, 4)
    plt.plot(t, envelope_waveform_fil)
    plt.title('Envelope * Filtered Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')

    plt.tight_layout()
    plt.show()


        

if __name__ == '__main__':
    main(0)
    main(1)
    main(2)
    main(3)