namespace :iso639 do
  desc "Import ISO-639 codes"
  task :import => :environment do
    require 'csv'

    # Raw files from http://www.sil.org/iso639-3/download.asp (adjust as
    # needed).
    ISO639_PATH = "iso-639-3_20120614.tab"
    ISO639_NAME_PATH = "iso-639-3_Name_Index_20120614.tab"
    ISO639_MACROLANGUAGES_PATH = "iso-639-3-macrolanguages_20120228.tab"

    # Languages extracted from our data files.
    LANGS = {}

    # Parse the main language file.
    CSV.open(ISO639_PATH, "rb:utf-8", headers: true, col_sep: "\t") do |csv|
      csv.each do |row|
        attrs = {
          iso_639_1: row["639_1"],
          iso_639_2t: row["639_2"],
          iso_639_2b: row["B_code"],
          iso_639_3: row["639_3"],
          name: row["Reference_Name"],
          iso_639_scope: row["Element_Scope"],
          iso_639_type: row["Language_Type"]
        }
        LANGS[row[0]] = attrs
      end
    end

    # Add inverted names.
    CSV.open(ISO639_NAME_PATH, "rb:utf-8", headers: true,
             col_sep: "\t") do |csv|
      csv.each do |row|
        if row["Reference_Name"] =~ /,/
          LANGS[row[0]][:inverted_name] = row["Reference_Name"]
        end
      end
    end

    Language.transaction do
      # Create database records.
      LANGS.keys.sort.each do |code|
        attrs = LANGS[code]

        # Sanitize our data a bit.
        next if attrs[:iso_639_type] =~ /Genetic|Geographic/
        next if attrs[:name] =~ /Reserved for|No linguistic/
        if attrs[:iso_639_1] && attrs[:iso_639_1].length > 2
          # Serbo-Croation has a note on this field: Deprecated.
          attrs[:iso_639_1].sub!(/ \(.*/, '')
        end

        attrs[:inverted_name] ||= attrs[:name]
        puts "Creating #{attrs[:inverted_name]}"
        lang = Language.create!(attrs)
        attrs[:model] = lang
      end

      # Hook up macrolanguages like Arabic.
      CSV.open(ISO639_MACROLANGUAGES_PATH, "rb:utf-8", headers: true,
          col_sep: "\t") do |csv|
        csv.each do |row|
          next unless LANGS[row[1]]
          lang = LANGS[row[1]][:model]
          macro = LANGS[row[0]][:model]
          lang.macrolanguage_id = macro.id
          lang.save!
        end
      end
    end
  end
end
