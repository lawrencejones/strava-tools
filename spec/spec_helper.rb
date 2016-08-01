require 'bundler/setup'
Bundler.setup(:default, :test)
Bundler.require(:test)

$LOAD_PATH << '../lib'

def load_fixture(file)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def load_json_fixture(file)
  JSON.parse(load_fixture(file))
end

def load_yaml_fixture(file)
  YAML.parse(load_fixture(file))
end
