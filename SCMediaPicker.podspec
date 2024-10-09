Pod::Spec.new do |s|
  s.name             = "SCMediaPicker"
  s.version          = "1.0.4"
  s.summary          = "A custom gallery picker with multiple selection support inspired by QBImagePicker."
  s.homepage         = "https://github.com/fotonotes/SCMediaPicker"
  s.license          = "MIT"
  s.author           = { "glennposadas" => "hello@glennvon.com" }
  s.source           = { :git => "https://github.com/fotonotes/SCMediaPicker.git", :tag => s.version.to_s }
  s.social_media_url = "https://www.glennvon.com"
  s.source_files     = "SCMediaPicker/**/*.{swift}"
  s.exclude_files    = "SCMediaPicker/SCMediaPicker.h"
  s.resources        = ["SCMediaPicker/**/*.{storyboard,lproj}"]
  s.platform         = :ios, "15.0"
  s.requires_arc     = true
  s.frameworks       = "Photos"
  s.swift_version = '5.0'
end
