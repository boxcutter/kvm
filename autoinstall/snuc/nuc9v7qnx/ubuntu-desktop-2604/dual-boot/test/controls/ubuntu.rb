describe package('openssh-server') do
  it { should be_installed }
end

target_user = input('target_user', value: 'autobot')

control 'gsettings-available' do
  impact 1.0
  title 'gsettings binary and required schemas exist'
  desc  'Ensure gsettings is present and the GNOME schemas we query are available'

  describe command('which gsettings') do
    its('exit_status') { should eq 0 }
  end

  # Check schemas exist (skip tests if not)
  %w[
    org.gnome.desktop.session
    org.gnome.desktop.screensaver
    org.gnome.settings-daemon.plugins.power
  ].each do |schema|
    describe command("sudo -iu #{target_user} gsettings list-schemas | grep -Fx '#{schema}'") do
      its('exit_status') { should eq 0 }
    end
  end
end

control 'gnome-screensaver-and-power-settings' do
  impact 1.0
  title 'Verify GNOME idle/screensaver/power settings via gsettings'
  only_if('gsettings not found') { command('which gsettings').exit_status == 0 }

  checks = [
    # schema, key, expected stdout (exactly as gsettings prints it)
    ['org.gnome.desktop.session',                    'idle-delay',                 'uint32 0'],
    ['org.gnome.desktop.screensaver',                'lock-enabled',               'false'],
    ['org.gnome.desktop.screensaver',                'idle-activation-enabled',    'false'],
    ['org.gnome.settings-daemon.plugins.power',      'sleep-inactive-ac-type',     "'nothing'"],
    ['org.gnome.settings-daemon.plugins.power',      'sleep-inactive-battery-type',"'nothing'"],
    ['org.gnome.settings-daemon.plugins.power',      'idle-dim',                   'false'],
  ]

  checks.each do |schema, key, expected|
    desc_str = "#{schema} #{key} should be #{expected}"
    describe(desc_str) do
      cmd = command("sudo -iu #{target_user} gsettings get #{schema} #{key}")
      it "has expected value (#{expected})" do
        expect(cmd.exit_status).to eq(0)
        expect(cmd.stdout.strip).to eq(expected)
      end
    end
  end
end
