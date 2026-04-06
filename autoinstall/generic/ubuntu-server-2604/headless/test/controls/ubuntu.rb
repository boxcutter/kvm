describe command('hostname') do
  its('stdout.strip') { should cmp 'generic-server' }
end

describe file('/etc/hostname') do
  its('content.strip') { should cmp 'generic-server' }
end
