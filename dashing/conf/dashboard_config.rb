module DashboardConfig
  def self.load()
    YAML.load(File.new('conf/dashboard.yaml', 'r').read)
  end
end