platform :ios, '10.3'
use_frameworks!

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

plugin 'cocoapods-keys',
  project: 'SpeechToText',
  keys: [
    'GoogleCloudSpeechApiKey',
  ]

target 'SpeechToText' do

  # Pods for SpeechToText
  pod 'googleapis', :path => '.'
  pod 'APAudioPlayer', '~> 0.0'

  target 'SpeechToTextTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SpeechToTextUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'SpeechToTextAction' do

  # Pods for SpeechToTextAction
  pod 'googleapis', :path => '.'
  pod 'APAudioPlayer', '~> 0.0'

end
