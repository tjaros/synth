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


# Wave types
SQR = 0
SAW = 1
TRI = 2


class Oscillator:
    def __init__(self) -> None:
        # Phase accumulator
        self.pa = 0
        self.pa_width = 28
        # Frequency control word
        self.fcw = 460856 #E4
        self.fcw_width = 16
        # waveform selector
        self.wave_type = SQR
        # clock frequency
        self.clk_freq = 192000
        self.sample_freq = 48000
        self.sample_t = 0
        # output width
        self.output_width = 24
    
    def reset(self) -> None:
        self.pa = 0
        self.sample_t = 0
        
    def wvf_square(self):
        return 0 if self.pa >> (self.pa_width - self.output_width) <= 2 ** (self.output_width - 1) else 2 ** self.output_width - 1

    def wvf_toothsaw(self):
        return self.pa >> (self.pa_width - self.output_width)

    def wvf_triangle(self):
        if self.pa < (2 ** (self.pa_width - 1)):
            return self.pa >> (self.pa_width - self.output_width)
        else:
            return (2 ** self.output_width - 1) - (self.pa >> (self.pa_width - self.output_width))

    
    def sample(self) -> int:
        # We want to sample at given frequency
        # Value of PA at x-th sample is 
        # word * x * (clk_freq/sample_freq) % 2^pa_width
        self.pa = (self.sample_t  * self.fcw * (self.clk_freq//self.sample_freq)) % (2**self.pa_width)
        self.sample_t += 1 
        
        if self.wave_type == SQR:
            return self.wvf_square()
        
        if self.wave_type == SAW:
            return self.wvf_toothsaw()
        
        if self.wave_type == TRI:
            return self.wvf_triangle()
        
        return 0

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
    osc_vwf = []
    envelope_osc_vwf = []
    filtered_envelope_osc_vwf = []
    
    osc = Oscillator()
    osc.wave_type = sel
    
    
    a1 = -1.36635865
    a2 = 0.52346993
    b0 = 0.03927782
    b1 = 0.07855564
    b2 = 0.03927782
    biquad_filter = BiquadFilter(b0, b1, b2, a1, a2)
    
    # Envelope parameters
    attack_time = 0.5
    decay_time = 0.25
    sustain_level = 0.25
    release_time = 0
    sample_rate = 48000

    # Instantiate the envelope generator
    envelope = EnvelopeGenerator(attack_time, decay_time, sustain_level, release_time, sample_rate)
    
    samples = 1000
    for i in  range(samples):
        
        # Trigger the envelope at the beginning of each note
        if i == 0:
            envelope.trigger()
        
        # osc
        osc_value = osc.sample()
        osc_value = (osc_value - (2**(osc.output_width-1))) / (2**(osc.output_width -1))
        # env
        envelope_value = envelope.tick()
        # Filter envelope * osc
        fil_value = biquad_filter.tick(osc_value * envelope_value)

        osc_vwf.append(osc_value)
        envelope_osc_vwf.append(envelope_value * osc_value)
        filtered_envelope_osc_vwf.append(envelope_value * fil_value)
        
        
    t = list(range(samples))
    # Plotting
    plt.figure(figsize=(10, 6))
    
    plt.subplot(3, 1, 1)
    plt.plot(t, osc_vwf)
    plt.title('Oscillator Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')

    plt.subplot(3, 1, 2)
    plt.plot(t, envelope_osc_vwf)
    plt.title('Envelope * Oscillator Waveform')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')

    plt.subplot(3, 1, 3)
    plt.plot(t, filtered_envelope_osc_vwf)
    plt.title('filter(Envelope * Oscillator Waveform)')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')
    
    plt.tight_layout()
    plt.show()


        

if __name__ == '__main__':
    main(SQR)
    main(SAW)
    main(TRI)