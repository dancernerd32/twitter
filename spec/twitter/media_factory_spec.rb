require 'helper'

describe Twitter::MediaFactory do
  describe '.new' do
    it 'generates a Photo' do
      media = Twitter::MediaFactory.new(id: 1, type: 'photo')
      expect(media).to be_a Twitter::Media::Photo
    end
    it 'generates a AnimatedGif' do
      media = Twitter::MediaFactory.new(id: 1, type: 'animated_gif')
      expect(media).to be_a Twitter::Media::AnimatedGif
    end
    it 'generates a Video' do
      media = Twitter::MediaFactory.new(id: 1, type: 'video')
      expect(media).to be_a Twitter::Media::Video
    end
    it 'raises an IndexError when type is not specified' do
      expect { Twitter::MediaFactory.new }.to raise_error(IndexError)
    end
  end
end
