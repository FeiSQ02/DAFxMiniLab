#pragma once

#include <JuceHeader.h>

class VolumeEffect
{
public:
	void prepare(double sampleRate);
	void reset();
	void setGainDb(float gainDb);
	void process(juce::AudioBuffer<float>& buffer);

private:
	juce::SmoothedValue<float> gainLinear{ 1.0f };
};
