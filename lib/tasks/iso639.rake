# -*- coding: utf-8 -*-
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

  HTLAL_KEYWORD_IDS = <<EOD
38,Afrikaans
1097,Albanian
1148,Amharic
1163,Ancient Egyptian
1125,Ancient Greek
7,Arabic
1151,Arabic (classical)
1147,Aramaic
1087,Armenian
1098,Azerbaijani
1101,Basque
26,Belarusian
1015,Bengali
1102,Breton
28,Bulgarian
1159,Burmese
15,Cantonese
36,Catalan
1103,Cherokee
1145,Cornish
30,Croatian
22,Czech
10,Danish
8,Dutch
2,English
18,Esperanto
1094,Estonian
34,Faroese
1086,Farsi/Persian
19,Finnish
39,Flemish
1,French
40,Frisian
1107,Gaelic (Irish)
1131,Gaelic (Scottish)
1144,Galician
1085,Georgian
3,German
43,Greek
1128,Greenlandic
1158,Guarani
1104,Gujarati
1105,Haitian Creole
1138,Hausa
1106,Hawaiian
1126,Hebrew
1150,Hebrew (biblical)
1084,Hindi
50,Hungarian
35,Icelandic
1139,Igbo
45,Indonesian
4,Italian
16,Japanese
1160,Javanese
1099,Kazakh
1090,Khmer
17,Korean
1109,Kurdish
1089,Laotian
46,Latin
1093,Latvian
1092,Lithuanian
1135,Luxembourgish
33,Macedonian
1146,Malagasy
1110,Malay
1111,Malayalam
1112,Maltese
14,Mandarin
1113,Maori
1155,Marathi
1133,Mayan languages
1088,Mongolian
1134,Nahuatl
1114,Nepali
12,Norwegian
37,Occitan
1115,Ojibwe
1149,Pali
1091,Pashto
23,Polish
11,Portuguese
1116,Punjabi
1153,Quechua
21,Romanian
6,Russian
51,Sanskrit
31,Serbian
29,Serbo-Croatian
1137,Shanghainese
1129,Sign Language
24,Slovak
32,Slovenian
1156,Somali
25,Sorbian
5,Spanish
98,Swahili
9,Swedish
48,Swiss-German
1123,Tagalog
1136,Taiwanese
1118,Tamil
1119,Telugu
20,Thai
1095,Tibetan
1130,Tok Pisin
1161,Toki Pona
13,Turkish
1122,Twi
1141,Tzeltal
1140,Tzotzil
27,Ukrainian
1132,Urdu
1143,Uyghur
1120,Uzbek
1124,Vietnamese
1127,Welsh
1157,Xhosa
41,Yiddish
1096,Yoruba
1121,Zulu
EOD

  HTLAL_PROFILE_LINKS = <<EOD
english.html English
spanish/index.html Spanish
french/index.html French
russian/index.html Russian
mandarin-chinese/index.html Mandarin
german/index.html German
italian/index.html Italian
japanese/index.html Japanese
arabic/index.html Arabic
thai.html Thai
korean/index.html Korean
cantonese-chinese/index.html Cantonese
Portuguese.html Portuguese
turkish/index.html Turkish
esperanto.html Esperanto
finnish.html Finnish
hungarian/index.html Hungarian
modern-greek/index.html Greek
serbo-croatian/index.html Serbo-Croatian
czech/index.html Czech
slovak/index.html Slovak
EOD

  HTLAL_PROFILE_BASE_DIR = "http://how-to-learn-any-language.com/e/languages/"

  HTLAL_LANGUAGE_IDS = <<EOD
40,Afrikaans
64,Albanian
120,Amharic
135,Ancient Egyptian
97,Ancient Greek
69,Apache
123,Arabic (classical)
157,Arabic (Egyptian)
155,Arabic (Gulf)
160,Arabic (Hassaniyya)
153,Arabic (Iraqi)
154,Arabic (Levantine)
159,Arabic (Maghribi)
158,Arabic (Sudanese)
7,Arabic (Written)
156,Arabic (Yemeni)
119,Aramaic
54,Armenian
144,Aymara
65,Azerbaijani
70,Basque
28,Belarusian
50,Bengali
122,Biblical Hebrew
164,Bikol languages
72,Breton
30,Bulgarian
131,Burmese
17,Cantonese
38,Catalan
161,Cebuano
73,Cherokee
117,Cornish
162,Corsican
143,Creole (English)
136,Creole (French)
32,Croatian
24,Czech
12,Danish
142,Dari
149,Domari
10,Dutch
2,English
20,Esperanto
61,Estonian
36,Faroese
21,Finnish
41,Flemish
1,French
42,Frisian
116,Galician
46,Georgian
3,German
45,Greek
100,Greenlandic
130,Guarani
74,Gujarati
138,Gypsy/Romani
75,Haitian Creole
110,Hausa
76,Hawaiian
44,Hindi
171,Hmong
146,Hokkien
52,Hungarian
37,Icelandic
111,Igbo
47,Indonesian
77,Irish
4,Italian
18,Japanese
132,Javanese
126,Kabyle
114,Kannada
66,Kazakh
172,Khasi
57,Khmer
173,Khoekhoegowab
78,Kirundi
19,Korean
79,Kurdish
145,Kyrgyz
56,Laotian
48,Latin
60,Latvian
163,Lingala
59,Lithuanian
168,Lowland Scots
107,Luxembourgish
35,Macedonian
118,Malagasy
80,Malay
81,Malayalam
82,Maltese
16,Mandarin
83,Maori
127,Marathi
124,Marshallese
105,Mayan languages
98,Modern Hebrew
55,Mongolian
106,Nahuatl
166,Navajo
84,Nepali
14,Norwegian
150,Nubian languages
39,Occitan
85,Ojibwe
169,Old English
139,Oriya
121,Pali
170,Papiamento
58,Pashto
49,Persian
25,Polish
13,Portuguese
134,Potwari
86,Punjabi
125,Quechua
23,Romanian
137,Romansh
6,Russian
148,Rwanda
53,Sanskrit
103,Scottish Gaelic
33,Serbian
31,Serbo-Croatian
109,Shanghainese
175,Sidamo
101,Sign Language
147,Sindhi
87,Sinhalese
26,Slovak
34,Slovenian
128,Somali
27,Sorbian
5,Spanish
88,Swahili
11,Swedish
51,Swiss-German
95,Tagalog
108,Taiwanese
141,Tajik
152,Tamasheq
151,Tamazight
89,Tamil
174,Tatar
90,Telugu
176,Tetum
22,Thai
62,Tibetan
167,Tigrinya
102,Tok Pisin
133,Toki Pona
15,Turkish
140,Turkmen
94,Twi
113,Tzeltal
112,Tzotzil
29,Ukrainian
104,Urdu
115,Uyghur
91,Uzbek
96,Vietnamese
99,Welsh
129,Xhosa
43,Yiddish
63,Yoruba
93,Zulu
EOD
  # Also 165,S?mi

  HTLAL_NONSTANDARD_NAMES = <<EOD
Ancient Egyptian,egy
Ancient Greek,grc
Arabic (classical),XXX,Maps to a dialect of Standard Arabic
Aramaic,arc
Cantonese,XXX,Maps to yue-can (Linguist List)
Farsi/Persian,fa
Flemish,vls
Frisian,XXX,Multiple matches
Gaelic (Irish),ga
Gaelic (Scottish),gd
Greek,el
Greenlandic,kl
Haitian Creole,ht
Hebrew (biblical),hbo
Khmer,km
Laotian,lo
Malay,ms
Mandarin,cmn
Mayan languages,XXX,No clear match
Nahuatl,XXX,Multiple matches
Nepali,ne
Occitan,oc
Ojibwe,oj
Pashto,XXX,Multiple matches as children of ps
Punjabi,pa
Shanghainese,wuu,Match to a larger language
Sorbian,XXX,Multiple matches
Swahili,sw
Swiss-German,gsw
Taiwanese,nan,Match to a larger language
Toki Pona,XXX,Not in ISO database
Uyghur,ug
Apache,XXX,Multiple matches
Arabic (Egyptian),arz
Arabic (Gulf),afb
Arabic (Hassaniyya),mey
Arabic (Iraqi),acm
Arabic (Levantine),Multiple matches
Arabic (Maghribi),XXX,Can't find
Arabic (Sudanese),apd
Arabic (Written),XXX,Maps to MSA or classical?
Arabic (Yemeni),XXX,Multiple matches
Biblical Hebrew,hbo
Bikol languages,bik
Creole (English),XXX,Muliple matches
Creole (French),XXX,Muliple matches
Gypsy/Romani,XXX,Multiple matches
Hokkien,nan,Match to a larger language
Khoekhoegowab,XXX,Multiple matches (hgm,naq)
Kirundi,rn
Kyrgyz,ky
Lowland Scots,sco
Modern Hebrew,he
Nubian languages,XXX,Maps to nub but it's not that simple
Old English,ang
Oriya,or
Potwari,phr
Rwanda,rw
Sign Language,XXX,Multiple matches
Sinhalese,si
Tamazight,XXX,Multiple matches
EOD

  HTLAL_NAME_TO_CODE = {}
  HTLAL_NONSTANDARD_NAMES.each_line do |line|
    name, code, comment = line.chomp.split(',', 3)
    next if code == 'XXX'
    HTLAL_NAME_TO_CODE[name] = code
  end

  def find_language(name)
    lang = Language.find_by_name(name)
    if lang.nil? && HTLAL_NAME_TO_CODE[name]
      lang = Language.find_by_code(HTLAL_NAME_TO_CODE[name])
    end
    if lang.nil?
      puts "Unknown language: #{name}"
    end
    lang
  end

  task :link_to_htlal => :environment do
    Language.transaction do
      HTLAL_KEYWORD_IDS.each_line do |line|
        id, name = line.chomp.split(/,/, 2)
        lang = find_language(name) or next
        lang.htlal_keyword_id ||= id
        lang.save!
      end

      HTLAL_PROFILE_LINKS.each_line do |line|
        link, name = line.chomp.split(/ /, 2)
        lang = find_language(name) or next
        lang.htlal_profile_url ||= HTLAL_PROFILE_BASE_DIR + link
        lang.save!
      end

      HTLAL_LANGUAGE_IDS.each_line do |line|
        id, name = line.chomp.split(/,/, 2)
        lang = find_language(name) or next
        lang.htlal_language_id ||= id
        lang.save!
      end
    end
  end

  LANGUAGE_ISO_QUERY = <<EOD
select distinct ?entity ?iso where {
  ?entity a <http://dbpedia.org/ontology/Language>.
  ?entity <http://dbpedia.org/property/iso> ?iso.
}
EOD

  LANGUAGE_LABEL_QUERY = <<EOD
select distinct ?entity ?label where {
  ?entity a <http://dbpedia.org/ontology/Language>.
  ?entity rdfs:label ?label.
}
EOD

  task :localize_language_names => :environment do
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")

    # Map Wikipedia articles to ISO 639 codes.
    puts "Querying dbpedia for ISO codes"
    iso_codes = {}
    sparql.query(LANGUAGE_ISO_QUERY).each_solution do |sln|
      url, iso = sln[:entity].to_s, sln[:iso].to_s
      (iso_codes[url] ||= []) << iso
    end
    puts "Found #{iso_codes.length} languages"

    Language.transaction do
      # Query for alternative article titles in various languages.
      puts "Querying dbpedia for language labels"
      sparql.query(LANGUAGE_LABEL_QUERY).each_solution do |sln|
        url = sln[:entity].to_s
        lang = sln[:label].language
        label = sln[:label].object.to_s

        # Search for matching languages.
        isos = iso_codes[url]
        if isos && url == 'http://dbpedia.org/resource/French_language'
          isos.reject! {|iso| iso == 'fri' }
        end
        langs = Language.where(code: isos)
        if langs.empty?
          puts "Can't find language for #{url}: #{isos.inspect}"
          next
        elsif langs.length > 1
          puts "Multiple languages match #{url}: #{isos.inspect}"
          next
        end

        # Search for the language to which this name belongs.
        in_lang = Language.where(code: lang).first
        unless in_lang
          puts "Can't find language used in name: #{lang}"
          next
        end

        # Create our new record.
        LanguageName.create!(language: langs.first, in_language: in_lang,
                             name: label)
      end
    end
  end
end
