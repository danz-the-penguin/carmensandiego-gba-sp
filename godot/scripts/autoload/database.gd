extends Node
## Database: World Cities, V.I.L.E. Suspects, Treasures, and Detective Ranks for GBA SP

const RANKS: Array[Dictionary] = [
	{"title": "ROOKIE", "required_cases": 0, "hops": 3, "deadline_hours": 40},
	{"title": "INVESTIGATOR", "required_cases": 2, "hops": 4, "deadline_hours": 44},
	{"title": "SR. DETECTIVE", "required_cases": 5, "hops": 4, "deadline_hours": 40},
	{"title": "INSPECTOR", "required_cases": 8, "hops": 5, "deadline_hours": 42},
	{"title": "ACE DETECTIVE", "required_cases": 12, "hops": 5, "deadline_hours": 38}
]

const SUSPECTS: Array[Dictionary] = [
	{
		"id": "carmen",
		"name": "CARMEN SANDIEGO",
		"sex": "Female",
		"hair": "Red",
		"vehicle": "Convertible",
		"hobby": "Tennis",
		"feature": "Ruby Ring",
		"quote": "You'll never catch me, ACME gumshoe!",
		"color": Color("#b91c1c")
	},
	{
		"id": "len_bulk",
		"name": "LEN BULK",
		"sex": "Male",
		"hair": "Black",
		"vehicle": "Motorcycle",
		"hobby": "Mountain Climbing",
		"feature": "Tattoo",
		"quote": "Outta my way, pencil pusher!",
		"color": Color("#1e293b")
	},
	{
		"id": "lady_agatha",
		"name": "LADY AGATHA",
		"sex": "Female",
		"hair": "Blonde",
		"vehicle": "Limousine",
		"hobby": "Croquet",
		"feature": "Monocle",
		"quote": "A lady always makes a clean getaway.",
		"color": Color("#facc15")
	},
	{
		"id": "nick_brunch",
		"name": "NICK BRUNCH",
		"sex": "Male",
		"hair": "Brown",
		"vehicle": "Convertible",
		"hobby": "Bowling",
		"feature": "Gold Watch",
		"quote": "You got nothing on me, detective.",
		"color": Color("#92400e")
	},
	{
		"id": "katherine_drib",
		"name": "KATHERINE DRIB",
		"sex": "Female",
		"hair": "Black",
		"vehicle": "Motorcycle",
		"hobby": "Skydiving",
		"feature": "Gold Locket",
		"quote": "Catch me if your parachute works!",
		"color": Color("#6b7280")
	},
	{
		"id": "fast_eddie",
		"name": "FAST EDDIE",
		"sex": "Male",
		"hair": "Red",
		"vehicle": "Limousine",
		"hobby": "Sailing",
		"feature": "Eyepatch",
		"quote": "Full sails ahead! You're eating my dust!",
		"color": Color("#dc2626")
	},
	{
		"id": "darlene_dirk",
		"name": "DARLENE DIRK",
		"sex": "Female",
		"hair": "Brown",
		"vehicle": "Convertible",
		"hobby": "Scuba Diving",
		"feature": "Scar",
		"quote": "You're swimming in deep waters, rookie.",
		"color": Color("#78350f")
	},
	{
		"id": "scar_graynolt",
		"name": "SCAR GRAYNOLT",
		"sex": "Male",
		"hair": "Blonde",
		"vehicle": "Motorcycle",
		"hobby": "Tennis",
		"feature": "Cane",
		"quote": "V.I.L.E. always stays one step ahead.",
		"color": Color("#eab308")
	}
]

const CITIES: Dictionary = {
	"london": {
		"id": "london",
		"name": "LONDON",
		"country": "United Kingdom",
		"currency": "Pounds Sterling",
		"flag": "a Union Jack with red and white crosses",
		"language": "English with Queen's accent",
		"landmark": "Big Ben and Tower Bridge",
		"connections": ["paris", "cairo", "reykjavik", "newyork"],
		"places": [
			{"name": "BANK OF ENGLAND", "witness": "Bank Teller"},
			{"name": "HEATHROW AIRPORT", "witness": "Flight Attendant"},
			{"name": "BRITISH MUSEUM", "witness": "Museum Curator"}
		]
	},
	"paris": {
		"id": "paris",
		"name": "PARIS",
		"country": "France",
		"currency": "French Francs",
		"flag": "a blue, white, and red vertical tricolor",
		"language": "French, greeting with 'Bonjour!'",
		"landmark": "the iron spire of the Eiffel Tower",
		"connections": ["london", "rome", "cairo", "athens"],
		"places": [
			{"name": "BANK OF FRANCE", "witness": "Bank Cashier"},
			{"name": "ORLY AIRPORT", "witness": "Customs Officer"},
			{"name": "LOUVRE MUSEUM", "witness": "Art Restorer"}
		]
	},
	"rome": {
		"id": "rome",
		"name": "ROME",
		"country": "Italy",
		"currency": "Italian Lira",
		"flag": "green, white, and red vertical bands",
		"language": "Italian, shouting 'Mamma Mia!'",
		"landmark": "the stone arches of the ancient Colosseum",
		"connections": ["paris", "athens", "cairo", "london"],
		"places": [
			{"name": "BANCA D'ITALIA", "witness": "Money Broker"},
			{"name": "FIUMICINO AIRPORT", "witness": "Ticket Agent"},
			{"name": "VATICAN ARCHIVES", "witness": "Archivist"}
		]
	},
	"athens": {
		"id": "athens",
		"name": "ATHENS",
		"country": "Greece",
		"currency": "Drachmas",
		"flag": "nine blue and white stripes with a white cross",
		"language": "Greek, greeting locals with 'Kalimera!'",
		"landmark": "the marble columns of the Parthenon",
		"connections": ["rome", "cairo", "paris", "kathmandu"],
		"places": [
			{"name": "NATIONAL BANK", "witness": "Banker"},
			{"name": "PIRAEUS HARBOR", "witness": "Ferry Captain"},
			{"name": "ACROPOLIS MUSEUM", "witness": "Archaeologist"}
		]
	},
	"cairo": {
		"id": "cairo",
		"name": "CAIRO",
		"country": "Egypt",
		"currency": "Egyptian Pounds",
		"flag": "red, white, and black with a golden eagle",
		"language": "Arabic, praising the Nile river",
		"landmark": "the Great Pyramids and Sphinx",
		"connections": ["london", "paris", "nairobi", "tokyo", "rome"],
		"places": [
			{"name": "BAZAAR MONEY CHANGER", "witness": "Spice Merchant"},
			{"name": "CAIRO INTERNATIONAL", "witness": "Dispatcher"},
			{"name": "EGYPTIAN MUSEUM", "witness": "Egyptologist"}
		]
	},
	"nairobi": {
		"id": "nairobi",
		"name": "NAIROBI",
		"country": "Kenya",
		"currency": "Kenyan Shillings",
		"flag": "black, red, and green stripes with a Masai shield",
		"language": "Swahili, bidding farewell with 'Jambo!'",
		"landmark": "savannas beneath snow-capped Mount Kenya",
		"connections": ["cairo", "sydney", "kathmandu", "rio"],
		"places": [
			{"name": "CENTRAL BANK", "witness": "Safari Guide"},
			{"name": "WILSON AIRPORT", "witness": "Bush Pilot"},
			{"name": "NATIONAL MUSEUM", "witness": "Naturalist"}
		]
	},
	"tokyo": {
		"id": "tokyo",
		"name": "TOKYO",
		"country": "Japan",
		"currency": "Japanese Yen",
		"flag": "a red circle on a white field (Hinomaru)",
		"language": "Japanese, bowing with 'Arigato'",
		"landmark": "Mount Fuji and Tokyo Tower",
		"connections": ["beijing", "sydney", "cairo", "sanfrancisco"],
		"places": [
			{"name": "BANK OF JAPAN", "witness": "Currency Clerk"},
			{"name": "NARITA AIRPORT", "witness": "Station Master"},
			{"name": "EDO MUSEUM", "witness": "Shrine Maiden"}
		]
	},
	"beijing": {
		"id": "beijing",
		"name": "BEIJING",
		"country": "China",
		"currency": "Chinese Yuan",
		"flag": "a red field with five golden yellow stars",
		"language": "Mandarin Chinese, saying 'Ni Hao'",
		"landmark": "the Great Wall winding across mountain ridges",
		"connections": ["tokyo", "kathmandu", "moscow", "sydney"],
		"places": [
			{"name": "PEOPLE'S BANK", "witness": "Tea Merchant"},
			{"name": "BEIJING CAPITAL", "witness": "Train Conductor"},
			{"name": "FORBIDDEN CITY", "witness": "Palace Historian"}
		]
	},
	"kathmandu": {
		"id": "kathmandu",
		"name": "KATHMANDU",
		"country": "Nepal",
		"currency": "Nepalese Rupees",
		"flag": "two stacked red pennants with sun and moon",
		"language": "Nepali, greeting travelers with 'Namaste'",
		"landmark": "Mount Everest towering over golden stupas",
		"connections": ["beijing", "athens", "nairobi", "tokyo"],
		"places": [
			{"name": "HIMALAYAN BANK", "witness": "Sherpa Porter"},
			{"name": "TRIBHUVAN AIRPORT", "witness": "Mountain Climber"},
			{"name": "SWAYAMBHUNATH TEMPLE", "witness": "Monk"}
		]
	},
	"sydney": {
		"id": "sydney",
		"name": "SYDNEY",
		"country": "Australia",
		"currency": "Australian Dollars",
		"flag": "the Union Jack and Southern Cross on blue",
		"language": "Aussie English, saying 'G'day mate!'",
		"landmark": "Sydney Opera House and Harbour Bridge",
		"connections": ["tokyo", "beijing", "nairobi", "sanfrancisco"],
		"places": [
			{"name": "COMMONWEALTH BANK", "witness": "Ferry Captain"},
			{"name": "KINGSFORD AIRPORT", "witness": "Lifeguard"},
			{"name": "OPERA HOUSE", "witness": "Stage Director"}
		]
	},
	"newyork": {
		"id": "newyork",
		"name": "NEW YORK",
		"country": "United States",
		"currency": "US Dollars",
		"flag": "thirteen red & white stripes with fifty stars",
		"language": "fast-paced American English",
		"landmark": "Statue of Liberty and Empire State Building",
		"connections": ["london", "sanfrancisco", "mexicocity", "rio"],
		"places": [
			{"name": "WALL STREET BANK", "witness": "Stockbroker"},
			{"name": "JFK AIRPORT", "witness": "Taxi Driver"},
			{"name": "METROPOLITAN MUSEUM", "witness": "Curator"}
		]
	},
	"sanfrancisco": {
		"id": "sanfrancisco",
		"name": "SAN FRANCISCO",
		"country": "United States",
		"currency": "US Dollars",
		"flag": "stars and stripes with a golden bear flag",
		"language": "California coastal dialect",
		"landmark": "the Golden Gate Bridge and historic Cable Cars",
		"connections": ["newyork", "tokyo", "sydney", "mexicocity"],
		"places": [
			{"name": "WELLS FARGO BANK", "witness": "Cable Car Gripman"},
			{"name": "SAN FRANCISCO AIRPORT", "witness": "Pier Fisherman"},
			{"name": "PALACE OF FINE ARTS", "witness": "Artist"}
		]
	},
	"mexicocity": {
		"id": "mexicocity",
		"name": "MEXICO CITY",
		"country": "Mexico",
		"currency": "Mexican Pesos",
		"flag": "vertical green, white, and red stripes with an eagle",
		"language": "Spanish, saying 'Por favor' and 'Gracias'",
		"landmark": "the Sun and Moon pyramids of Teotihuacan",
		"connections": ["newyork", "sanfrancisco", "rio", "paris"],
		"places": [
			{"name": "BANCO DE MEXICO", "witness": "Mariachi Musician"},
			{"name": "BENITO JUAREZ AIRPORT", "witness": "Zocalo Merchant"},
			{"name": "ANTHROPOLOGY MUSEUM", "witness": "Archaeologist"}
		]
	},
	"rio": {
		"id": "rio",
		"name": "RIO DE JANEIRO",
		"country": "Brazil",
		"currency": "Brazilian Cruzeiros",
		"flag": "green with a yellow rhombus and celestial blue globe",
		"language": "Portuguese, humming samba beats",
		"landmark": "Christ the Redeemer and Sugarloaf Mountain",
		"connections": ["mexicocity", "newyork", "nairobi", "london"],
		"places": [
			{"name": "BANCO DO BRASIL", "witness": "Samba Dancer"},
			{"name": "GALEAO AIRPORT", "witness": "Beach Vendor"},
			{"name": "HISTORIC MUSEUM", "witness": "Historian"}
		]
	},
	"moscow": {
		"id": "moscow",
		"name": "MOSCOW",
		"country": "Russia",
		"currency": "Russian Rubles",
		"flag": "three horizontal stripes of white, blue, and red",
		"language": "Russian, raising a glass saying 'Za zdorovye!'",
		"landmark": "onion domes of Saint Basil's Cathedral and Red Square",
		"connections": ["beijing", "london", "paris", "reykjavik"],
		"places": [
			{"name": "GUM ARCADE BANK", "witness": "Matryoshka Vendor"},
			{"name": "SHEREMETYEVO AIRPORT", "witness": "Metro Attendant"},
			{"name": "STATE HISTORICAL MUSEUM", "witness": "Curator"}
		]
	},
	"reykjavik": {
		"id": "reykjavik",
		"name": "REYKJAVIK",
		"country": "Iceland",
		"currency": "Icelandic Krona",
		"flag": "a blue field with a red cross outlined in white",
		"language": "Icelandic, recounting ancient Viking sagas",
		"landmark": "cascading geysers and dancing Northern Lights",
		"connections": ["london", "newyork", "moscow", "paris"],
		"places": [
			{"name": "LANDSBANKI", "witness": "Geologist"},
			{"name": "KEFLAVIK AIRPORT", "witness": "Harbor Fisher"},
			{"name": "NATIONAL SAGA MUSEUM", "witness": "Saga Scholar"}
		]
	}
}

const TREASURES: Array[Dictionary] = [
	{"name": "THE CROWN JEWELS", "city": "london"},
	{"name": "THE MONA LISA", "city": "paris"},
	{"name": "THE ROSETTA STONE", "city": "london"},
	{"name": "TUTANKHAMUN'S GOLD MASK", "city": "cairo"},
	{"name": "THE JADE EMPEROR STATUE", "city": "beijing"},
	{"name": "THE COLOSSEUM KEYSTONE", "city": "rome"},
	{"name": "THE GOLDEN BOOMERANG", "city": "sydney"},
	{"name": "THE AZTEC SUN STONE", "city": "mexicocity"},
	{"name": "THE SACRED EVEREST PRAYER WHEEL", "city": "kathmandu"},
	{"name": "THE IMPERIAL FABERGE EGG", "city": "moscow"},
	{"name": "THE RIFT VALLEY DIAMOND", "city": "nairobi"},
	{"name": "THE STATUE OF LIBERTY TORCH", "city": "newyork"}
]
