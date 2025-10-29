describe command('hostname') do
  its('stdout.strip') { should cmp 'generic' }
end

describe file('/etc/hostname') do
  its('content.strip') { should cmp 'generic' }
end
