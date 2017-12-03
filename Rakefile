require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

file "libexec/helper" => FileList["helper/*"] do
  system "xcrun", "-sdk", "macosx", "swiftc",
    "-Osize", # optimize for size
    "-target", "x86_64-apple-macosx10.12",
    "-o", "libexec/helper",
    *Dir["helper/helper.swift"] or fail

  system "codesign",
    "--sign", "Developer ID Application: Samuel Cochran (9C4D79M493)",
    "--identifier", "9C4D79M493.com.github.sj26.rubygems-keychain.helper",
    "--entitlements", "helper/entitlements.plist",
    "libexec/helper" or fail
end

task :build => "libexec/helper"
