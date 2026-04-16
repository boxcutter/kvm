describe command('hostname') do
  its('stdout.strip') { should cmp 'generic-desktop' }
end

describe file('/etc/hostname') do
  its('content.strip') { should cmp 'generic-desktop' }
end

 %w[apt-daily.timer apt-daily-upgrade.timer].each do |timer|
  describe systemd_service(timer) do
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe command("systemctl is-enabled #{timer}") do
    its('stdout.strip') { should cmp 'disabled' }
  end

  describe command("systemctl is-active #{timer}") do
    its('stdout.strip') { should match(/inactive|failed|dead/) }
  end
end


%w[apt-daily.service apt-daily-upgrade.service].each do |svc|
  describe command("systemctl is-enabled #{svc}") do
     its('stdout.strip') { should cmp 'masked' }
  end

  describe command("systemctl show #{svc} -p UnitFileState --value") do
    its('stdout.strip') { should cmp 'masked' }
  end
end

describe command('gsettings get org.gnome.desktop.session idle-delay') do
  its('stdout.strip') { should cmp 'uint32 0' }
end

describe command('gsettings get org.gnome.desktop.screensaver lock-enabled') do
  its('stdout.strip') { should cmp 'false' }
end

describe command('gsettings get org.gnome.desktop.screensaver idle-activation-enabled') do
  its('stdout.strip') { should cmp 'false' }
end

describe command('gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type') do
  its('stdout.strip') { should cmp "'nothing'" }
end

describe command('gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type') do
  its('stdout.strip') { should cmp "'nothing'" }
end
