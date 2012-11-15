#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright 2011, Alastair Brunton
#
# MIT license
#

# Install backup, s3sync, fog, mail, whenever

package "libxslt" do
  package_name "libxslt-dev"
  action :install
end

package "libxml-dev" do
  package_name "libxml2-dev"
  action :install
end

[['backup', '~> 3.0.25'], ['fog', '~> 1.4.0'], ['parallel', '~> 0.5.12'], ['mail', '~> 2.4.0'], 'whenever'].each do |gem|
  gem_name = [gem].flatten[0]
  gem_version = [gem].flatten[1]
  
  if node[:backup][:rvm]
    rvm_gem gem_name do
      ruby_string node[:rvm][:default_ruby]
      version gem_version if gem_version
      action :install
    end
  else
    gem_package gem_name do
      version gem_version if gem_version
      action :install
    end
  end
end

backup_dir = 'Backup'

["#{backup_dir}", "#{backup_dir}/config", "#{backup_dir}/log"].each do |dir|
  execute "mkdir /home/#{node[:backup][:backup_user]}/#{dir}" do
    user node[:backup][:backup_user]
    only_if { !File.directory?("/home/#{node[:backup][:backup_user]}/#{dir}") }
  end
end

template "/home/#{node[:backup][:backup_user]}/#{backup_dir}/config.rb" do
  owner node[:backup][:backup_user]
  source "config.rb.erb"
  variables(:config => node[:backup])
end


# Whenever config setup.
template "/home/#{node[:backup][:backup_user]}/#{backup_dir}/config/schedule.rb" do
  owner node[:backup][:backup_user]
  source "schedule.rb.erb"
  variables(:config => node[:backup])
end

template "/etc/logrotate.d/whenever_log" do
  owner "root"
  source "logrotate.erb"
  variables(:backup_path => "/home/#{node[:backup][:backup_user]}/#{backup_dir}")
end

execute "whenever" do
  user node[:backup][:backup_user]
  command "whenever --update-crontab"
  cwd "/home/#{node[:backup][:backup_user]}/#{backup_dir}"
  action :run
end
