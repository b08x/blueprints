# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

OWNER = 'b08x'.freeze

DOCKER_FLAGS = ENV['DOCKER_FLAGS']

TAG_LENGTH = 12

def git_revision
  `git rev-parse HEAD`.chomp
end

def tag_from_commit_sha1
  git_revision[...TAG_LENGTH]
end

revision_tag = tag_from_commit_sha1
image = 'blueprints'

desc "Build #{OWNER}/#{image} image"
task "build/#{image}" do
  sh "docker buildx build --rm --force-rm -t #{OWNER}/#{image}:latest ."
end

desc "Tag #{OWNER}/#{image} image"
task "tag/#{image}" => "build/#{image}" do
  sh "docker tag #{OWNER}/#{image}:latest #{OWNER}/#{image}:#{revision_tag}"
end

desc "Push #{OWNER}/#{image} image"
task "push/#{image}" => "tag/#{image}" do
  sh "docker push #{OWNER}/#{image}:latest"
  sh "docker push #{OWNER}/#{image}:#{revision_tag}"
end
