namespace :iso639 do
  def codes(attrs)
    %w(code iso_639_1 iso_639_2t iso_639_2b iso_639_3 bt_equiv).map do |code|
      attrs[code.to_sym]
    end.compact.sort.uniq
  end

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
    NAMES = {}
    DUP_NAMES = {}

    # Parse the main language file.
    CSV.open(ISO639_PATH, "rb:utf-8", headers: true, col_sep: "\t") do |csv|
      csv.each do |row|
        attrs = {
          code: row[0],
          iso_639_1: row["639_1"],
          iso_639_2t: row["639_2"],
          iso_639_2b: row["B_Code"],
          iso_639_3: row["639_3"],
          bt_equiv: row["bt_equiv"],
          alt_code: nil,
          name: row["Reference_Name"],
          iso_639_scope: row["Element_Scope"],
          iso_639_type: row["Language_Type"]
        }
        next if attrs[:name] == 'Reserved for local use'
        if LANGS[attrs[:code]]
          raise "Duplicate primary key: #{attrs[:code]}"
        end
        if NAMES[attrs[:name]]
          puts "Duplicate: #{attrs[:name]}"
          old_attrs = NAMES[attrs[:name]]
          if attrs[:bt_equiv] == old_attrs[:code] && attrs[:code] == old_attrs[:bt_equiv]
            puts "  BT Equivalent"
            full = [attrs, old_attrs].select {|a| a[:iso_639_2b] }
            full.length == 1 or raise "Weird conflict at #{attrs[:name]}"
            LANGS.delete(old_attrs[:code])
            LANGS[full.first[:code]] = full.first
            #puts "  #{full.first.inspect}"
            next
          elsif codes(attrs) == codes(old_attrs)
            puts "  Dropping exact duplicate"
          elsif !codes(attrs).any? {|c| codes(old_attrs).include?(c) }
            puts "  No actual overlap, making names unique"
            attrs[:name] += " [#{attrs[:code]}]"
            old_attrs[:name] += " [#{old_attrs[:code]}]"
            DUP_NAMES[attrs[:code]] = true
            DUP_NAMES[old_attrs[:code]] = true
          elsif attrs[:name] =~ /^(Serbian|Croatian)$/
            puts "  Merging a Balkans record"
            new = codes(attrs).select {|c| !codes(old_attrs).include?(c) }
            new.length == 1 or raise "Help! Can't fix the Balkans records"
            old_attrs[:alt_code] = new.first
            next
          else
            puts "  !!! PARTIAL OVERLAP for #{attrs[:name]}"
            puts "    #{codes(attrs).join(', ')}"
            puts "    #{codes(old_attrs).join(', ')}"
          end
        else
          NAMES[attrs[:name]] = attrs
        end
        LANGS[attrs[:code]] = attrs
      end
    end

    # Add inverted names.
    CSV.open(ISO639_NAME_PATH, "rb:utf-8", headers: true,
             col_sep: "\t") do |csv|
      csv.each do |row|
        if row["Reference_Name"] =~ /,/
          next if row[0] == 'mhu' # Inverted name is non-unique???
          attrs = LANGS[row[0]]
          attrs[:inverted_name] = row["Reference_Name"] if attrs
          if DUP_NAMES[row[0]]
            attrs[:inverted_name] += " [#{attrs[:code]}]"
          end
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
        attrs.delete(:bt_equiv)
        attrs.delete(:code)
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
