/**
 * Where in the World is Carmen Sandiego? - Game Boy Edition
 * Game Data: Cities, Suspects, Treasures, Clues & Detective Ranks
 */

const GAME_RANKS = [
  { title: "ROOKIE", requiredCases: 0, hops: 3, deadlineHours: 40 },
  { title: "INVESTIGATOR", requiredCases: 2, hops: 4, deadlineHours: 44 },
  { title: "SR. DETECTIVE", requiredCases: 5, hops: 4, deadlineHours: 40 },
  { title: "INSPECTOR", requiredCases: 8, hops: 5, deadlineHours: 42 },
  { title: "ACE DETECTIVE", requiredCases: 12, hops: 5, deadlineHours: 38 }
];

const SUSPECTS_DATA = [
  {
    id: "carmen",
    name: "CARMEN SANDIEGO",
    sex: "Female",
    hair: "Red",
    vehicle: "Convertible",
    hobby: "Tennis",
    feature: "Ruby Ring",
    quote: "You'll never catch me, ACME gumshoe!"
  },
  {
    id: "len_bulk",
    name: "LEN BULK",
    sex: "Male",
    hair: "Black",
    vehicle: "Motorcycle",
    hobby: "Mountain Climbing",
    feature: "Tattoo",
    quote: "Outta my way, pencil pusher!"
  },
  {
    id: "lady_agatha",
    name: "LADY AGATHA",
    sex: "Female",
    hair: "Blonde",
    vehicle: "Limousine",
    hobby: "Croquet",
    feature: "Monocle",
    quote: "A lady always makes a clean getaway."
  },
  {
    id: "nick_brunch",
    name: "NICK BRUNCH",
    sex: "Male",
    hair: "Brown",
    vehicle: "Convertible",
    hobby: "Bowling",
    feature: "Gold Watch",
    quote: "You got nothing on me, detective."
  },
  {
    id: "katherine_drib",
    name: "KATHERINE DRIB",
    sex: "Female",
    hair: "Black",
    vehicle: "Motorcycle",
    hobby: "Skydiving",
    feature: "Gold Locket",
    quote: "Catch me if your parachute works!"
  },
  {
    id: "fast_eddie",
    name: "FAST EDDIE",
    sex: "Male",
    hair: "Red",
    vehicle: "Limousine",
    hobby: "Sailing",
    feature: "Eyepatch",
    quote: "Full sails ahead! You're eating my dust!"
  },
  {
    id: "darlene_dirk",
    name: "DARLENE DIRK",
    sex: "Female",
    hair: "Brown",
    vehicle: "Convertible",
    hobby: "Scuba Diving",
    feature: "Scar",
    quote: "You're swimming in deep waters, rookie."
  },
  {
    id: "scar_graynolt",
    name: "SCAR GRAYNOLT",
    sex: "Male",
    hair: "Blonde",
    vehicle: "Motorcycle",
    hobby: "Tennis",
    feature: "Cane",
    quote: "V.I.L.E. always stays one step ahead."
  }
];

const CITIES_DATA = {
  london: {
    id: "london",
    name: "LONDON",
    country: "United Kingdom",
    currency: "Pounds Sterling",
    flagDescription: "a red cross on white with diagonal red-and-white crosses (Union Jack)",
    language: "English with a distinguished Queen's accent",
    geography: "an island nation bordered by the North Sea and English Channel",
    landmark: "Big Ben and Tower Bridge",
    funFact: "a city famous for double-decker buses and high tea",
    connections: ["paris", "cairo", "reykjavik", "newyork"],
    places: [
      { type: "bank", name: "BANK OF ENGLAND", witness: "Bank Teller" },
      { type: "airport", name: "HEATHROW AIRPORT", witness: "Flight Attendant" },
      { type: "library", name: "BRITISH MUSEUM", witness: "Museum Curator" }
    ],
    skyline: "london"
  },
  paris: {
    id: "paris",
    name: "PARIS",
    country: "France",
    currency: "French Francs",
    flagDescription: "three vertical stripes of blue, white, and red (Tricolore)",
    language: "fluent French and greeted everyone with 'Bonjour!'",
    geography: "a country bordered by the Bay of Biscay and the Alps",
    landmark: "the iron spire of the Eiffel Tower",
    funFact: "a romantic capital along the river Seine",
    connections: ["london", "rome", "cairo", "athens"],
    places: [
      { type: "bank", name: "BANK OF FRANCE", witness: "Bank Cashier" },
      { type: "airport", name: "ORLY AIRPORT", witness: "Customs Officer" },
      { type: "library", name: "LOUVRE MUSEUM", witness: "Art Restorer" }
    ],
    skyline: "paris"
  },
  rome: {
    id: "rome",
    name: "ROME",
    country: "Italy",
    currency: "Italian Lira",
    flagDescription: "three vertical bands of green, white, and red",
    language: "Italian, exclaiming 'Mamma Mia!'",
    geography: "a boot-shaped peninsula jutting into the Mediterranean",
    landmark: "the ancient stone arches of the Colosseum",
    funFact: "a city surrounded by seven historic hills",
    connections: ["paris", "athens", "cairo", "london"],
    places: [
      { type: "bank", name: "BANCA D'ITALIA", witness: "Money Changer" },
      { type: "airport", name: "FIUMICINO AIRPORT", witness: "Ticket Agent" },
      { type: "library", name: "VATICAN ARCHIVES", witness: "Archivist" }
    ],
    skyline: "rome"
  },
  athens: {
    id: "athens",
    name: "ATHENS",
    country: "Greece",
    currency: "Drachmas",
    flagDescription: "nine blue and white stripes with a white cross",
    language: "Greek, saying 'Kalimera' to the locals",
    geography: "the rugged southern tip of the Balkan Peninsula surrounded by Aegean islands",
    landmark: "the marble columns of the Parthenon on the Acropolis",
    funFact: "the cradle of Western civilization and ancient democracy",
    connections: ["rome", "cairo", "paris", "kathmandu"],
    places: [
      { type: "bank", name: "NATIONAL BANK", witness: "Banker" },
      { type: "airport", name: "PIRAEUS HARBOR", witness: "Ferry Captain" },
      { type: "library", name: "ACROPOLIS MUSEUM", witness: "Archaeologist" }
    ],
    skyline: "athens"
  },
  cairo: {
    id: "cairo",
    name: "CAIRO",
    country: "Egypt",
    currency: "Egyptian Pounds",
    flagDescription: "three horizontal stripes of red, white, and black with a golden eagle",
    language: "Arabic and praised the majesty of the Nile",
    geography: "the northeast corner of Africa bordered by the Sahara Desert",
    landmark: "the Great Pyramids and the silent Sphinx",
    funFact: "the historic land of pharaohs and papyrus scrolls",
    connections: ["london", "paris", "nairobi", "tokyo", "rome"],
    places: [
      { type: "bank", name: "BAZAAR MONEY CHANGER", witness: "Spice Merchant" },
      { type: "airport", name: "CAIRO INTERNATIONAL", witness: "Flight Dispatcher" },
      { type: "library", name: "EGYPTIAN MUSEUM", witness: "Egyptologist" }
    ],
    skyline: "cairo"
  },
  nairobi: {
    id: "nairobi",
    name: "NAIROBI",
    country: "Kenya",
    currency: "Kenyan Shillings",
    flagDescription: "horizontal stripes of black, red, and green with a traditional Masai shield",
    language: "Swahili, bidding farewell with 'Jambo!' and 'Asante'",
    geography: "the great East African Rift Valley under the equator",
    landmark: "vast savannas beneath snow-capped Mount Kenya",
    funFact: "a safari haven known as the Green City in the Sun",
    connections: ["cairo", "sydney", "kathmandu", "rio"],
    places: [
      { type: "bank", name: "CENTRAL BANK", witness: "Safari Guide" },
      { type: "airport", name: "WILSON AIRPORT", witness: "Bush Pilot" },
      { type: "library", name: "NATIONAL MUSEUM", witness: "Naturalist" }
    ],
    skyline: "nairobi"
  },
  tokyo: {
    id: "tokyo",
    name: "TOKYO",
    country: "Japan",
    currency: "Japanese Yen",
    flagDescription: "a bold red circle centered on a pure white field (Hinomaru)",
    language: "Japanese, bowing politely while saying 'Arigato gozaimasu'",
    geography: "a Pacific island archipelago famous for volcanic hot springs",
    landmark: "the snow-crowned peak of Mount Fuji and Tokyo Tower",
    funFact: "a futuristic metropolis of bullet trains and neon lights",
    connections: ["beijing", "sydney", "cairo", "sanfrancisco"],
    places: [
      { type: "bank", name: "BANK OF JAPAN", witness: "Currency Broker" },
      { type: "airport", name: "NARITA AIRPORT", witness: "Station Master" },
      { type: "library", name: "EDO-TOKYO MUSEUM", witness: "Shrine Maiden" }
    ],
    skyline: "tokyo"
  },
  beijing: {
    id: "beijing",
    name: "BEIJING",
    country: "China",
    currency: "Chinese Yuan",
    flagDescription: "a red field with five golden yellow stars in the canton",
    language: "Mandarin Chinese, saying 'Ni Hao' to shopkeepers",
    geography: "the vast East Asian mainland bordered by the Yellow River",
    landmark: "the Great Wall winding across rolling mountain ridges",
    funFact: "home to the Forbidden City and imperial dragon palaces",
    connections: ["tokyo", "kathmandu", "moscow", "sydney"],
    places: [
      { type: "bank", name: "PEOPLE'S BANK", witness: "Tea Merchant" },
      { type: "airport", name: "BEIJING CAPITAL", witness: "Train Conductor" },
      { type: "library", name: "FORBIDDEN CITY", witness: "Palace Historian" }
    ],
    skyline: "beijing"
  },
  kathmandu: {
    id: "kathmandu",
    name: "KATHMANDU",
    country: "Nepal",
    currency: "Nepalese Rupees",
    flagDescription: "the world's only non-quadrilateral flag with two stacked red pennants",
    language: "Nepali, greeting travelers with palms pressed together: 'Namaste'",
    geography: "the highest mountain plateau on Earth nestled in the Himalayas",
    landmark: "Mount Everest towering over golden Buddhist stupas",
    funFact: "a valley filled with fluttering colorful prayer flags",
    connections: ["beijing", "athens", "nairobi", "tokyo"],
    places: [
      { type: "bank", name: "HIMALAYAN BANK", witness: "Sherpa Porter" },
      { type: "airport", name: "TRIBHUVAN AIRPORT", witness: "Mountain Climber" },
      { type: "library", name: "SWAYAMBHUNATH TEMPLE", witness: "Monk" }
    ],
    skyline: "kathmandu"
  },
  sydney: {
    id: "sydney",
    name: "SYDNEY",
    country: "Australia",
    currency: "Australian Dollars",
    flagDescription: "a blue field with the Union Jack and the Southern Cross constellation",
    language: "Australian English, greeting mates with 'G'day!'",
    geography: "the world's largest island continent surrounded by the Pacific and Indian oceans",
    landmark: "the sweeping white sail-roofs of the Sydney Opera House",
    funFact: "home to hopping red kangaroos and the Great Barrier Reef",
    connections: ["tokyo", "beijing", "nairobi", "sanfrancisco"],
    places: [
      { type: "bank", name: "COMMONWEALTH BANK", witness: "Harbour Ferryman" },
      { type: "airport", name: "KINGSFORD SMITH AIRPORT", witness: "Lifeguard" },
      { type: "library", name: "SYDNEY OPERA HOUSE", witness: "Stage Director" }
    ],
    skyline: "sydney"
  },
  newyork: {
    id: "newyork",
    name: "NEW YORK",
    country: "United States",
    currency: "US Dollars",
    flagDescription: "thirteen red and white stripes with fifty stars on a blue canton",
    language: "fast-talking American English shouting for a yellow cab",
    geography: "the bustling Atlantic seaboard of North America",
    landmark: "the torch-bearing Statue of Liberty and Empire State Building",
    funFact: "the Big Apple, famous for Broadway theaters and yellow cabs",
    connections: ["london", "sanfrancisco", "mexicocity", "rio"],
    places: [
      { type: "bank", name: "WALL STREET BANK", witness: "Stockbroker" },
      { type: "airport", name: "JFK INTERNATIONAL", witness: "Taxi Driver" },
      { type: "library", name: "METROPOLITAN MUSEUM", witness: "Curator" }
    ],
    skyline: "newyork"
  },
  sanfrancisco: {
    id: "sanfrancisco",
    name: "SAN FRANCISCO",
    country: "United States",
    currency: "US Dollars",
    flagDescription: "stars and stripes with a golden grizzly bear state flag",
    language: "California slang and talk about Pacific coastal fog",
    geography: "a foggy bay along the rugged Pacific coastline",
    landmark: "the majestic orange towers of the Golden Gate Bridge",
    funFact: "famous for steep hills, historic cable cars, and Alcatraz Island",
    connections: ["newyork", "tokyo", "sydney", "mexicocity"],
    places: [
      { type: "bank", name: "WELLS FARGO BANK", witness: "Cable Car Gripman" },
      { type: "airport", name: "SAN FRANCISCO AIRPORT", witness: "Pier Fisherman" },
      { type: "library", name: "PALACE OF FINE ARTS", witness: "Artist" }
    ],
    skyline: "sanfrancisco"
  },
  mexicocity: {
    id: "mexicocity",
    name: "MEXICO CITY",
    country: "Mexico",
    currency: "Mexican Pesos",
    flagDescription: "vertical green, white, and red stripes with an eagle perched on a cactus",
    language: "Spanish, asking for directions with 'Por favor' and 'Gracias'",
    geography: "a high volcanic plateau surrounded by the Sierra Madre",
    landmark: "the Sun and Moon pyramids of ancient Teotihuacan",
    funFact: "built over the ancient Aztec capital of Tenochtitlan",
    connections: ["newyork", "sanfrancisco", "rio", "paris"],
    places: [
      { type: "bank", name: "BANCO DE MEXICO", witness: "Mariachi Musician" },
      { type: "airport", name: "BENITO JUAREZ AIRPORT", witness: "Zocalo Merchant" },
      { type: "library", name: "ANTHROPOLOGY MUSEUM", witness: "Archaeologist" }
    ],
    skyline: "mexicocity"
  },
  rio: {
    id: "rio",
    name: "RIO DE JANEIRO",
    country: "Brazil",
    currency: "Brazilian Cruzeiros",
    flagDescription: "a green field with a yellow rhombus and a blue celestial globe",
    language: "Portuguese, humming lively samba and bossa nova rhythms",
    geography: "the tropical Atlantic coast of South America bordering the Amazon",
    landmark: "the towering Christ the Redeemer atop Corcovado mountain",
    funFact: "home to the world's most vibrant Carnival celebration",
    connections: ["mexicocity", "newyork", "nairobi", "london"],
    places: [
      { type: "bank", name: "BANCO DO BRASIL", witness: "Samba Dancer" },
      { type: "airport", name: "GALEAO AIRPORT", witness: "Beach Vendor" },
      { type: "library", name: "NATIONAL HISTORIC MUSEUM", witness: "Historian" }
    ],
    skyline: "rio"
  },
  moscow: {
    id: "moscow",
    name: "MOSCOW",
    country: "Russia",
    currency: "Russian Rubles",
    flagDescription: "three horizontal stripes of white, blue, and red",
    language: "Russian, raising a glass saying 'Za zdorovye!'",
    geography: "the vast northern Eurasian plain between Europe and Siberia",
    landmark: "the swirling candy-colored onion domes of Saint Basil's Cathedral",
    funFact: "the historic Red Square and deep ornate subway stations",
    connections: ["beijing", "london", "paris", "reykjavik"],
    places: [
      { type: "bank", name: "GUM ARCADE BANK", witness: "Matryoshka Vendor" },
      { type: "airport", name: "SHEREMETYEVO AIRPORT", witness: "Metro Attendant" },
      { type: "library", name: "STATE HISTORICAL MUSEUM", witness: "Curator" }
    ],
    skyline: "moscow"
  },
  reykjavik: {
    id: "reykjavik",
    name: "REYKJAVIK",
    country: "Iceland",
    currency: "Icelandic Krona",
    flagDescription: "a blue field with a red cross outlined in white",
    language: "Icelandic, recounting ancient Viking sagas",
    geography: "a sub-Arctic volcanic island warmed by geothermal hot springs",
    landmark: "cascading geysers and the dancing emerald Northern Lights",
    funFact: "the northernmost capital in the world, heated by the Earth itself",
    connections: ["london", "newyork", "moscow", "paris"],
    places: [
      { type: "bank", name: "LANDSBANKI", witness: "Geologist" },
      { type: "airport", name: "KEFLAVIK AIRPORT", witness: "Harbor Fisher" },
      { type: "library", name: "NATIONAL SAGA MUSEUM", witness: "Saga Scholar" }
    ],
    skyline: "reykjavik"
  }
};

const TREASURES_DATA = [
  { name: "THE CROWN JEWELS", city: "london" },
  { name: "THE MONA LISA", city: "paris" },
  { name: "THE ROSETTA STONE", city: "london" },
  { name: "TUTANKHAMUN'S GOLD MASK", city: "cairo" },
  { name: "THE JADE EMPEROR STATUE", city: "beijing" },
  { name: "THE COLOSSEUM KEYSTONE", city: "rome" },
  { name: "THE GOLDEN BOOMERANG", city: "sydney" },
  { name: "THE AZTEC SUN STONE", city: "mexicocity" },
  { name: "THE SACRED EVEREST PRAYER WHEEL", city: "kathmandu" },
  { name: "THE IMPERIAL FABERGE EGG", city: "moscow" },
  { name: "THE RIFT VALLEY DIAMOND", city: "nairobi" },
  { name: "THE STATUE OF LIBERTY TORCH", city: "newyork" }
];

if (typeof window !== "undefined") {
  window.GAME_RANKS = GAME_RANKS;
  window.SUSPECTS_DATA = SUSPECTS_DATA;
  window.CITIES_DATA = CITIES_DATA;
  window.TREASURES_DATA = TREASURES_DATA;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = { GAME_RANKS, SUSPECTS_DATA, CITIES_DATA, TREASURES_DATA };
}
