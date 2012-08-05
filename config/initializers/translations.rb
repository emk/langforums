# Information about an available translation.
Translation = Struct.new :code, :name

# Load the list of available translations and language names
TRANSLATIONS = []
YAML.load_file(File.join(Rails.root, 'config', 'translations.yml')).each do |l|
  TRANSLATIONS << Translation.new(l['code'], l['name'])
end

