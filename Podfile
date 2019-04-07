platform :ios, '10.3'
use_frameworks!

plugin 'cocoapods-keys',
  project: 'SpeechToText',
  keys: [
    'GoogleCloudSpeechApiKey',
  ]

target 'SpeechToText' do

  # Pods for SpeechToText
  pod 'googleapis', :path => '.'

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

end
