require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

file "Helper.app" => FileList["src/*"] do |task|
  system "rm", "-rf", "Helper.app"

  system "mkdir", "-p", "Helper.app/Contents/MacOS"

  system "cp", "src/helper.provisionprofile", "Helper.app/Contents/embedded.provisionprofile"

  system "cp", "src/info.plist", "Helper.app/Contents/Info.plist" or fail

  system "xcrun", "-sdk", "macosx", "swiftc",
    "-Osize", # optimize for size
    "-o", "Helper.app/Contents/MacOS/Helper",
    *Dir["src/helper.swift"] or fail

  system "codesign",
    "--deep",
    "--sign", "Developer ID Application",
    "--entitlements", "src/helper.entitlements",
    "Helper.app" or fail
end

task :build => "Helper.app"
