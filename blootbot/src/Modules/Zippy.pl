#
# zippy -- infobot module for Zippy the Pinhead quotes
#          hacked up by Rich Lafferty (mendel) <rich@vax2.concordia.ca>
#
# Data gratuitously swiped from fortune-mod-9708, the 'fortune' program.
#

package zippy;

my $no_zippy; # Can't think of any situation in which this won't work..

sub zippy::get {
    unless (@yows) { # read data unless it's been read already.
	print "Reading...\n";
	while (<DATA>) {
	    chomp;
	    push @yows, $_;
	}
    }

    if ($no_zippy) { # ..but just in case :-)
	return "YOW! I'm an INFOBOT without ZIPPY!" if $main::addressed;
    }

    srand(); # fork seems to not change rand. force it here
    my $yow = $yows[rand(@yows)];

    &::performStrictReply($yow);
}

1;

=pod

=head1 NAME

Zippy.pl - Yow!  Am I having fun yet?

=head1 PREREQUISITES

None.

=head1 PARAMETERS

zippy

=head1 PUBLIC INTERFACE

	[yow|be zippy]

=head1 DESCRIPTION

It's OBVIOUS ... The FURS never reached ISTANBUL ... You were an EXTRA
in the REMAKE of "TOPKAPI" ... Go home to your WIFE ... She's making
FRENCH TOAST!

=head1 AUTHORS

Rich Lafferty (mendel) <rich@vax2.concordia.ca>

=cut

__DATA__
A can of ASPARAGUS, 73 pigeons, some LIVE ammo, and a FROZEN DAQUIRI!!
A dwarf is passing out somewhere in Detroit!
A shapely CATHOLIC SCHOOLGIRL is FIDGETING inside my costume..
A wide-eyed, innocent UNICORN, poised delicately in a MEADOW filled with LILACS, LOLLIPOPS & small CHILDREN at the HUSH of twilight??
Actually, what I'd like is a little toy spaceship!!
All I can think of is a platter of organic PRUNE CRISPS being trampled by an army of swarthy, Italian LOUNGE SINGERS ...
All of a sudden, I want to THROW OVER my promising ACTING CAREER, grow a LONG BLACK BEARD and wear a BASEBALL HAT!! ...  Although I don't know WHY!!
All of life is a blur of Republicans and meat!
All right, you degenerates!  I want this place evacuated in 20 seconds!
All this time I've been VIEWING a RUSSIAN MIDGET SODOMIZE a HOUSECAT!
Alright, you!!  Imitate a WOUNDED SEAL pleading for a PARKING SPACE!!
Am I accompanied by a PARENT or GUARDIAN?
Am I elected yet?
Am I in GRADUATE SCHOOL yet?
Am I SHOPLIFTING?
America!!  I saw it all!!  Vomiting!  Waving!  JERRY FALWELLING into your void tube of UHF oblivion!!  SAFEWAY of the mind ...
An air of FRENCH FRIES permeates my nostrils!!
An INK-LING?  Sure -- TAKE one!!  Did you BUY any COMMUNIST UNIFORMS??
An Italian is COMBING his hair in suburban DES MOINES!
And furthermore, my bowling average is unimpeachable!!!
ANN JILLIAN'S HAIR makes LONI ANDERSON'S HAIR look like RICARDO MONTALBAN'S HAIR!
Are the STEWED PRUNES still in the HAIR DRYER?
Are we live or on tape?
Are we on STRIKE yet?
Are we THERE yet?
Are we THERE yet?  My MIND is a SUBMARINE!!
Are you mentally here at Pizza Hut??
Are you selling NYLON OIL WELLS??  If so, we can use TWO DOZEN!!
Are you still an ALCOHOLIC?
As President I have to go vacuum my coin collection!
Awright, which one of you hid my PENIS ENVY?
BARBARA STANWYCK makes me nervous!!
Barbie says, Take quaaludes in gin and go to a disco right away!
But Ken says, WOO-WOO!!  No credit at "Mr. Liquor"!!
BARRY ... That was the most HEART-WARMING rendition of "I DID IT MY WAY" I've ever heard!!
Being a BALD HERO is almost as FESTIVE as a TATTOOED KNOCKWURST.
BELA LUGOSI is my co-pilot ...
BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI-BI- ... bleakness ... desolation ... plastic forks ...
Bo Derek ruined my life!
Boy, am I glad it's only 1971...
Boys, you have ALL been selected to LEAVE th' PLANET in 15 minutes!!
But they went to MARS around 1953!!
But was he mature enough last night at the lesbian masquerade?
Can I have an IMPULSE ITEM instead?
Can you MAIL a BEAN CAKE?
Catsup and Mustard all over the place!  It's the Human Hamburger!
CHUBBY CHECKER just had a CHICKEN SANDWICH in downtown DULUTH!
Civilization is fun!  Anyway, it keeps me busy!!
Clear the laundromat!!  This whirl-o-matic just had a nuclear meltdown!!
Concentrate on th'cute, li'l CARTOON GUYS!  Remember the SERIAL NUMBERS!!  Follow the WHIPPLE AVE. EXIT!!  Have a FREE PEPSI!!  Turn LEFT at th'HOLIDAY INN!!  JOIN the CREDIT WORLD!!  MAKE me an OFFER!!!
CONGRATULATIONS!  Now should I make thinly veiled comments about DIGNITY, self-esteem and finding TRUE FUN in your RIGHT VENTRICLE??
Content:  80% POLYESTER, 20% DACRONi ... The waitress's UNIFORM sheds TARTAR SAUCE like an 8" by 10" GLOSSY ...
Could I have a drug overdose?
Did an Italian CRANE OPERATOR just experience uninhibited sensations in a MALIBU HOT TUB?
Did I do an INCORRECT THING??
Did I say I was a sardine?  Or a bus???
Did I SELL OUT yet??
Did YOU find a DIGITAL WATCH in YOUR box of VELVEETA?
Did you move a lot of KOREAN STEAK KNIVES this trip, Dingy?
DIDI ... is that a MARTIAN name, or, are we in ISRAEL?
Didn't I buy a 1951 Packard from you last March in Cairo?
Disco oil bussing will create a throbbing naugahide pipeline running straight to the tropics from the rug producing regions and devalue the dollar!
Do I have a lifestyle yet?
Do you guys know we just passed thru a BLACK HOLE in space?
Do you have exactly what I want in a plaid poindexter bar bat??
Do you like "TENDER VITTLES"?
Do you think the "Monkees" should get gas on odd or even days?
Does someone from PEORIA have a SHORTER ATTENTION span than me? does your DRESSING ROOM have enough ASPARAGUS?
DON'T go!!  I'm not HOWARD COSELL!!  I know POLISH JOKES ... WAIT!!
Don't go!!  I AM Howard Cosell! ... And I DON'T know Polish jokes!!
Don't hit me!!  I'm in the Twilight Zone!!!
Don't SANFORIZE me!!
Don't worry, nobody really LISTENS to lectures in MOSCOW, either! ... FRENCH, HISTORY, ADVANCED CALCULUS, COMPUTER PROGRAMMING, BLACK STUDIES, SOCIOBIOLOGY! ...  Are there any QUESTIONS??
Edwin Meese made me wear CORDOVANS!!
Eisenhower!!  Your mimeograph machine upsets my stomach!!
Either CONFESS now or we go to "PEOPLE'S COURT"!!
Everybody gets free BORSCHT!
Everybody is going somewhere!!  It's probably a garage sale or a disaster Movie!!
Everywhere I look I see NEGATIVITY and ASPHALT ...
Excuse me, but didn't I tell you there's NO HOPE for the survival of OFFSET PRINTING? FEELINGS are cascading over me!!!
Finally, Zippy drives his 1958 RAMBLER METROPOLITAN into the faculty dining room.
First, I'm going to give you all the ANSWERS to today's test ...  So just plug in your SONY WALKMANS and relax!!
FOOLED you!  Absorb EGO SHATTERING impulse rays, polyester poltroon!! for ARTIFICIAL FLAVORING!!
Four thousand different MAGNATES, MOGULS & NABOBS are romping in my gothic solarium!!
FROZEN ENTREES may be flung by members of opposing SWANSON SECTS ...
FUN is never having to say you're SUSHI!!
Gee, I feel kind of LIGHT in the head now, knowing I can't make my satellite dish PAYMENTS!
Gibble, Gobble, we ACCEPT YOU ...
Give them RADAR-GUIDED SKEE-BALL LANES and VELVEETA BURRITOS!!
Go on, EMOTE!  I was RAISED on thought balloons!!
GOOD-NIGHT, everybody ... Now I have to go administer FIRST-AID to my pet LEISURE SUIT!!
HAIR TONICS, please!!
Half a mind is a terrible thing to waste!
Hand me a pair of leather pants and a CASIO keyboard -- I'm living for today!
Has everybody got HALVAH spread all over their ANKLES?? ...  Now, it's time to "HAVE A NAGEELA"!! ... he dominates the DECADENT SUBWAY SCENE.
He is the MELBA-BEING ... the ANGEL CAKE ... XEROX him ... XEROX him -- He probably just wants to take over my CELLS and then EXPLODE inside me like a BARREL of runny CHOPPED LIVER!  Or maybe he'd like to PSYCHOLIGICALLY TERRORISE ME until I have no objection to a RIGHT-WING MILITARY TAKEOVER of my apartment!!  I guess I should call AL PACINO!
HELLO KITTY gang terrorizes town, family STICKERED to death!
HELLO, everybody, I'm a HUMAN!!
Hello, GORRY-O!!  I'm a GENIUS from HARVARD!!
Hello.  I know the divorce rate among unmarried Catholic Alaskan females!!
Hello.  Just walk along and try NOT to think about your INTESTINES being almost FORTY YARDS LONG!!
Hello...  IRON CURTAIN?  Send over a SAUSAGE PIZZA!  World War III?  No thanks!
Hello?  Enema Bondage?  I'm calling because I want to be happy, I guess ...
Here I am at the flea market but nobody is buying my urine sample bottles ...
Here I am in 53 B.C. and all I want is a dill pickle!!
Here I am in the POSTERIOR OLFACTORY LOBULE but I don't see CARL SAGAN anywhere!!
Here we are in America ... when do we collect unemployment?
Hey, wait a minute!!  I want a divorce!! ... you're not Clint Eastwood!!
Hey, waiter!  I want a NEW SHIRT and a PONY TAIL with lemon sauce!
Hiccuping & trembling into the WASTE DUMPS of New Jersey like some drunken CABBAGE PATCH DOLL, coughing in line at FIORUCCI'S!!
Hmmm ... a CRIPPLED ACCOUNTANT with a FALAFEL sandwich is HIT by a TROLLEY-CAR ...
Hmmm ... A hash-singer and a cross-eyed guy were SLEEPING on a deserted island, when ...
Hmmm ... a PINHEAD, during an EARTHQUAKE, encounters an ALL-MIDGET FIDDLE ORCHESTRA ... ha ... ha ...
Hmmm ... an arrogant bouquet with a subtle suggestion of POLYVINYL CHLORIDE ...
Hold the MAYO & pass the COSMIC AWARENESS ...
HOORAY, Ronald!!  Now YOU can marry LINDA RONSTADT too!!
How do I get HOME?
How do you explain Wayne Newton's POWER over millions?  It's th' MOUSTACHE ...  Have you ever noticed th' way it radiates SINCERITY, HONESTY & WARMTH?
It's a MOUSTACHE you want to take HOME and introduce to NANCY SINATRA!
How many retured bricklayers from FLORIDA are out purchasing PENCIL
SHARPENERS right NOW??
How's it going in those MODULAR LOVE UNITS??
How's the wife?  Is she at home enjoying capitalism?
hubub, hubub, HUBUB, hubub, hubub, hubub, HUBUB, hubub, hubub, hubub.
HUGH BEAUMONT died in 1982!!
HUMAN REPLICAS are inserted into VATS of NUTRITIONAL YEAST ...
I always have fun because I'm out of my mind!!!
I am a jelly donut.  I am a jelly donut.
I am a traffic light, and Alan Ginzberg kidnapped my laundry in 1927!
I am covered with pure vegetable oil and I am writing a best seller!
I am deeply CONCERNED and I want something GOOD for BREAKFAST!
I am having FUN...  I wonder if it's NET FUN or GROSS FUN?
I am NOT a nut....
I appoint you ambassador to Fantasy Island!!!
I brought my BOWLING BALL -- and some DRUGS!!
I can't decide which WRONG TURN to make first!!  I wonder if BOB GUCCIONE has these problems!
I can't think about that.  It doesn't go with HEDGES in the shape of LITTLE LULU -- or ROBOTS making BRICKS ...
I demand IMPUNITY!
I didn't order any WOO-WOO ... Maybe a YUBBA ... But no WOO-WOO!
I don't believe there really IS a GAS SHORTAGE.. I think it's all just a BIG HOAX on the part of the plastic sign salesmen -- to sell more numbers!!
... I don't know why but, suddenly, I want to discuss declining I.Q. LEVELS with a blue ribbon SENATE SUB-COMMITTEE!
I don't know WHY I said that ... I think it came from the FILLINGS in my read molars ...
... I don't like FRANK SINATRA or his CHILDREN. I don't understand the HUMOUR of the THREE STOOGES!!
I feel ... JUGULAR ...
I feel better about world problems now!
I feel like a wet parking meter on Darvon!
I feel like I am sharing a ``CORN-DOG'' with NIKITA KHRUSCHEV ...
I feel like I'm in a Toilet Bowl with a thumbtack in my forehead!!
I feel partially hydrogenated!
I fill MY industrial waste containers with old copies of the "WATCHTOWER" and then add HAWAIIAN PUNCH to the top ...  They look NICE in the yard ...
I guess it was all a DREAM ... or an episode of HAWAII FIVE-O ...
I guess you guys got BIG MUSCLES from doing too much STUDYING!
I had a lease on an OEDIPUS COMPLEX back in '81 ...
I had pancake makeup for brunch!
I have a TINY BOWL in my HEAD
I have a very good DENTAL PLAN.  Thank you.
I have a VISION!  It's a RANCID double-FISHWICH on an ENRICHED BUN!!
I have accepted Provolone into my life!
I have many CHARTS and DIAGRAMS..
... I have read the INSTRUCTIONS ...
-- I have seen the FUN --
I have seen these EGG EXTENDERS in my Supermarket ... I have read the INSTRUCTIONS ...
I have the power to HALT PRODUCTION on all TEENAGE SEX COMEDIES!!
I HAVE to buy a new "DODGE MISER" and two dozen JORDACHE JEANS because my viewscreen is "USER-FRIENDLY"!!
I haven't been married in over six years, but we had sexual counseling every day from Oral Roberts!!
I hope I bought the right relish ... zzzzzzzzz ...
I hope something GOOD came in the mail today so I have a REASON to live!!
I hope the ``Eurythmics'' practice birth control ...
I hope you millionaires are having fun!  I just invested half your life savings in yeast!!
I invented skydiving in 1989!
I joined scientology at a garage sale!!
I just forgot my whole philosophy of life!!!
I just got my PRINCE bumper sticker ... But now I can't remember WHO he is ...
I just had a NOSE JOB!!
I just had my entire INTESTINAL TRACT coated with TEFLON!
I just heard the SEVENTIES were over!!  And I was just getting in touch with my LEISURE SUIT!!
I just remembered something about a TOAD!
I KAISER ROLL?!  What good is a Kaiser Roll without a little COLE SLAW on the SIDE?
I Know A Joke!!
I know how to do SPECIAL EFFECTS!!
I know th'MAMBO!!  I have a TWO-TONE CHEMISTRY SET!!
I know things about TROY DONAHUE that can't even be PRINTED!!
I left my WALLET in the BATHROOM!!
I like the way ONLY their mouths move ...  They look like DYING OYSTERS
I like your SNOOPY POSTER!!
-- I love KATRINKA because she drives a PONTIAC.  We're going away now.  I fed the cat.
I love ROCK 'N ROLL!  I memorized the all WORDS to "WIPE-OUT" in 1965!!
I need to discuss BUY-BACK PROVISIONS with at least six studio SLEAZEBALLS!!
I once decorated my apartment entirely in ten foot salad forks!!
I own seven-eighths of all the artists in downtown Burbank!
I put aside my copy of "BOWLING WORLD" and think about GUN CONTROL legislation...
I represent a sardine!!
I request a weekend in Havana with Phil Silvers!
... I see TOILET SEATS ...
I selected E5 ... but I didn't hear "Sam the Sham and the Pharoahs"!
I smell a RANCID CORN DOG!
I smell like a wet reducing clinic on Columbus Day!
I think I am an overnight sensation right now!!
... I think I'd better go back to my DESK and toy with a few common MISAPPREHENSIONS ...
I think I'll KILL myself by leaping out of this 14th STORY WINDOW while reading ERICA JONG'S poetry!!
I think my career is ruined!
I used to be a FUNDAMENTALIST, but then I heard about the HIGH RADIATION LEVELS and bought an ENCYCLOPEDIA!!
... I want a COLOR T.V. and a VIBRATING BED!!!
I want a VEGETARIAN BURRITO to go ... with EXTRA MSG!!
I want a WESSON OIL lease!!
I want another RE-WRITE on my CEASAR SALAD!!
I want EARS!  I want two ROUND BLACK EARS to make me feel warm 'n secure!!
... I want FORTY-TWO TRYNEL FLOATATION SYSTEMS installed within SIX AND A HALF HOURS!!!
I want the presidency so bad I can already taste the hors d'oeuvres.
I want to dress you up as TALLULAH BANKHEAD and cover you with VASELINE and WHEAT THINS ...
I want to kill everyone here with a cute colorful Hydrogen Bomb!!
... I want to perform cranial activities with Tuesday Weld!!
I want to read my new poem about pork brains and outer space ...
I want to so HAPPY, the VEINS in my neck STAND OUT!!
I want you to MEMORIZE the collected poems of EDNA ST VINCENT MILLAY ... BACKWARDS!!
I want you to organize my PASTRY trays ... my TEA-TINS are gleaming in formation like a ROW of DRUM MAJORETTES -- please don't be FURIOUS with me --
I was born in a Hostess Cupcake factory before the sexual revolution!
I was making donuts and now I'm on a bus!
I wish I was a sex-starved manicurist found dead in the Bronx!!
I wish I was on a Cincinnati street corner holding a clean dog!
I wonder if I could ever get started in the credit world?
I wonder if I ought to tell them about my PREVIOUS LIFE as a COMPLETE STRANGER?
I wonder if I should put myself in ESCROW!!
I wonder if there's anything GOOD on tonight?
I would like to urinate in an OVULAR, porcelain pool --
I'd like MY data-base JULIENNED and stir-fried!
I'd like some JUNK FOOD ... and then I want to be ALONE --
I'll eat ANYTHING that's BRIGHT BLUE!!
I'll show you MY telex number if you show me YOURS ...
I'm a fuschia bowling ball somewhere in Brittany
I'm a GENIUS!  I want to dispute sentence structure with SUSAN SONTAG!!
I'm a nuclear submarine under the polar ice cap and I need a Kleenex!
I'm also against BODY-SURFING!!
I'm also pre-POURED pre-MEDITATED and pre-RAPHAELITE!!
I'm ANN LANDERS!!  I can SHOPLIFT!!
I'm changing the CHANNEL ... But all I get is commercials for "RONCO MIRACLE BAMBOO STEAMERS"!
I'm continually AMAZED at th'breathtaking effects of WIND EROSION!!
I'm definitely not in Omaha!
I'm DESPONDENT ... I hope there's something DEEP-FRIED under this miniature DOMED STADIUM ...
I'm dressing up in an ill-fitting IVY-LEAGUE SUIT!!  Too late...
I'm EMOTIONAL now because I have MERCHANDISING CLOUT!!
I'm encased in the lining of a pure pork sausage!!
I'm GLAD I remembered to XEROX all my UNDERSHIRTS!!
I'm gliding over a NUCLEAR WASTE DUMP near ATLANTA, Georgia!!
I'm having a BIG BANG THEORY!!
I'm having a MID-WEEK CRISIS!
I'm having a RELIGIOUS EXPERIENCE ... and I don't take any DRUGS
I'm having a tax-deductible experience!  I need an energy crunch!!
I'm having an emotional outburst!!
I'm having an EMOTIONAL OUTBURST!!  But, uh, WHY is there a WAFFLE in my PAJAMA POCKET??
I'm having BEAUTIFUL THOUGHTS about the INSIPID WIVES of smug and wealthy CORPORATE LAWYERS ...
I'm having fun HITCHHIKING to CINCINNATI or FAR ROCKAWAY!! ...
I'm IMAGINING a sensuous GIRAFFE, CAVORTING in the BACK ROOM of a KOSHER DELI
I'm in direct contact with many advanced fun CONCEPTS.
I'm into SOFTWARE!
I'm meditating on the FORMALDEHYDE and the ASBESTOS leaking into my PERSONAL SPACE!!
I'm mentally OVERDRAWN!  What's that SIGNPOST up ahead?  Where's ROD STERLING when you really need him?
I'm not an Iranian!!  I voted for Dianne Feinstein!!
I'm not available for comment..
I'm pretending I'm pulling in a TROUT!  Am I doing it correctly??
I'm pretending that we're all watching PHIL SILVERS instead of RICARDO MONTALBAN!
I'm QUIETLY reading the latest issue of "BOWLING WORLD" while my wife and two children stand QUIETLY BY ...
I'm rated PG-34!!
I'm receiving a coded message from EUBIE BLAKE!!
I'm RELIGIOUS!!  I love a man with a HAIRPIECE!!  Equip me with MISSILES!!
I'm reporting for duty as a modern person.  I want to do the Latin Hustle now!
I'm shaving!!  I'M SHAVING!!
I'm sitting on my SPEED QUEEN ... To me, it's ENJOYABLE ... I'm WARM ... I'm VIBRATORY ...
I'm thinking about DIGITAL READ-OUT systems and computer-generated IMAGE FORMATIONS ...
I'm totally DESPONDENT over the LIBYAN situation and the price of CHICKEN ...
I'm using my X-RAY VISION to obtain a rare glimpse of the INNER WORKINGS of this POTATO!!
I'm wearing PAMPERS!!
I'm wet!  I'm wild!
I'm young ... I'm HEALTHY ... I can HIKE THRU CAPT GROGAN'S LUMBAR REGIONS!
I'm ZIPPY the PINHEAD and I'm totally committed to the festive mode.
I've got a COUSIN who works in the GARMENT DISTRICT ...
I've got an IDEA!!  Why don't I STARE at you so HARD, you forget your SOCIAL SECURITY NUMBER!!
I've read SEVEN MILLION books!! ... ich bin in einem dusenjet ins jahr 53 vor chr ... ich lande im antiken Rom ...  einige gladiatoren spielen scrabble ... ich rieche PIZZA ...
If a person is FAMOUS in this country, they have to go on the ROAD for MONTHS at a time and have their name misspelled on the SIDE of a GREYHOUND SCENICRUISER!!
If elected, Zippy pledges to each and every American a 55-year-old houseboy ...
If I am elected no one will ever have to do their laundry again!
If I am elected, the concrete barriers around the WHITE HOUSE will be replaced by tasteful foam replicas of ANN MARGARET!
If I felt any more SOPHISTICATED I would DIE of EMBARRASSMENT!
If I had a Q-TIP, I could prevent th' collapse of NEGOTIATIONS!! ... If I had heart failure right now, I couldn't be a more fortunate man!!
If I pull this SWITCH I'll be RITA HAYWORTH!!  Or a SCIENTOLOGIST!
if it GLISTENS, gobble it!!
If our behavior is strict, we do not need fun!
If Robert Di Niro assassinates Walter Slezak, will Jodie Foster marry Bonzo??
In 1962, you could buy a pair of SHARKSKIN SLACKS, with a "Continental Belt," for $10.99!!
In Newark the laundromats are open 24 hours a day!
INSIDE, I have the same personality disorder as LUCY RICARDO!!
Inside, I'm already SOBBING!
Is a tattoo real, like a curb or a battleship?  Or are we suffering in Safeway?
Is he the MAGIC INCA carrying a FROG on his shoulders??  Is the FROG his GUIDELIGHT??  It is curious that a DOG runs already on the ESCALATOR ...
Is it 1974?  What's for SUPPER?  Can I spend my COLLEGE FUND in one wild afternoon??
Is it clean in other dimensions?
Is it NOUVELLE CUISINE when 3 olives are struggling with a scallop in a plate of SAUCE MORNAY?
Is something VIOLENT going to happen to a GARBAGE CAN?
Is this an out-take from the "BRADY BUNCH"?
Is this going to involve RAW human ecstasy?
Is this TERMINAL fun?
Is this the line for the latest whimsical YUGOSLAVIAN drama which also makes you want to CRY and reconsider the VIETNAM WAR?
Isn't this my STOP?!
It don't mean a THING if you ain't got that SWING!!
It was a JOKE!!  Get it??  I was receiving messages from DAVID LETTERMAN!!
YOW!!
It's a lot of fun being alive ... I wonder if my bed is made?!?
It's NO USE ... I've gone to "CLUB MED"!!
It's OBVIOUS ... The FURS never reached ISTANBUL ... You were an EXTRA in the REMAKE of "TOPKAPI" ... Go home to your WIFE ... She's making FRENCH TOAST!
It's OKAY -- I'm an INTELLECTUAL, too.
It's the RINSE CYCLE!!  They've ALL IGNORED the RINSE CYCLE!!
JAPAN is a WONDERFUL planet -- I wonder if we'll ever reach their level of COMPARATIVE SHOPPING ...
Jesuit priests are DATING CAREER DIPLOMATS!!
Jesus is my POSTMASTER GENERAL ...
Kids, don't gross me off ... "Adventures with MENTAL HYGIENE" can be carried too FAR!
Kids, the seven basic food groups are GUM, PUFF PASTRY, PIZZA, PESTICIDES, ANTIBIOTICS, NUTRA-SWEET and MILK DUDS!!
Laundry is the fifth dimension!!  ... um ... um ... th' washing machine is a black hole and the pink socks are bus drivers who just fell in!!
LBJ, LBJ, how many JOKES did you tell today??!
Leona, I want to CONFESS things to you ... I want to WRAP you in a SCARLET ROBE trimmed with POLYVINYL CHLORIDE ... I want to EMPTY your ASHTRAYS ...
Let me do my TRIBUTE to FISHNET STOCKINGS ...
Let's all show human CONCERN for REVERAND MOON's legal difficulties!!
Let's send the Russians defective lifestyle accessories!
Life is a POPULARITY CONTEST!  I'm REFRESHINGLY CANDID!!
Like I always say -- nothing can beat the BRATWURST here in DUSSELDORF!!
Loni Anderson's hair should be LEGALIZED!!
Look DEEP into the OPENINGS!!  Do you see any ELVES or EDSELS ... or a HIGHBALL?? ...
Look into my eyes and try to forget that you have a Macy's charge card!
Look!  A ladder!  Maybe it leads to heaven, or a sandwich!
LOOK!!  Sullen American teens wearing MADRAS shorts and "Flock of Seagulls" HAIRCUTS!
Make me look like LINDA RONSTADT again!!
Mary Tyler Moore's SEVENTH HUSBAND is wearing my DACRON TANK TOP in a cheap hotel in HONOLULU!
Maybe we could paint GOLDIE HAWN a rich PRUSSIAN BLUE --
MERYL STREEP is my obstetrician!
MMM-MM!!  So THIS is BIO-NEBULATION!
Mmmmmm-MMMMMM!!  A plate of STEAMING PIECES of a PIG mixed with the shreds of SEVERAL CHICKENS!! ... Oh BOY!!  I'm about to swallow a TORN-OFF section of a COW'S LEFT LEG soaked in COTTONSEED OIL and SUGAR!! ... Let's see ... Next, I'll have the GROUND-UP flesh of CUTE, BABY LAMBS fried in the MELTED, FATTY TISSUES from a warm-blooded animal someone once PETTED!! ... YUM!!  That was GOOD!!  For DESSERT, I'll have a TOFU BURGER with BEAN SPROUTS on a stone-ground, WHOLE WHEAT BUN!!
Mr and Mrs PED, can I borrow 26.7% of the RAYON TEXTILE production of the INDONESIAN archipelago?
My Aunt MAUREEN was a military advisor to IKE & TINA TURNER!!
My BIOLOGICAL ALARM CLOCK just went off ... It has noiseless DOZE FUNCTION and full kitchen!!
My CODE of ETHICS is vacationing at famed SCHROON LAKE in upstate New York!!
My EARS are GONE!!
My face is new, my license is expired, and I'm under a doctor's care!!!!
My haircut is totally traditional!
MY income is ALL disposable!
My LESLIE GORE record is BROKEN ...
My life is a patio of fun!
My mind is a potato field ...
My mind is making ashtrays in Dayton ...
My nose feels like a bad Ronald Reagan movie ...
My NOSE is NUMB!
... My pants just went on a wild rampage through a Long Island Bowling Alley!!
My pants just went to high school in the Carlsbad Caverns!!!
My polyvinyl cowboy wallet was made in Hong Kong by Montgomery Clift!
My uncle Murray conquered Egypt in 53 B.C.  And I can prove it too!!
My vaseline is RUNNING...
NANCY!!  Why is everything RED?!
NATHAN ... your PARENTS were in a CARCRASH!!  They're VOIDED -- They COLLAPSED They had no CHAINSAWS ... They had no MONEY MACHINES ... They did PILLS in SKIMPY GRASS SKIRTS ... Nathan, I EMULATED them ... but they were OFF-KEY ...
NEWARK has been REZONED!!  DES MOINES has been REZONED!!
Nipples, dimples, knuckles, NICKLES, wrinkles, pimples!!
Not SENSUOUS ... only "FROLICSOME" ... and in need of DENTAL WORK ... in PAIN!!!
Now I am depressed ...
Now I think I just reached the state of HYPERTENSION that comes JUST BEFORE you see the TOTAL at the SAFEWAY CHECKOUT COUNTER!
Now I understand the meaning of "THE MOD SQUAD"!
Now I'm being INVOLUNTARILY shuffled closer to the CLAM DIP with the BROKEN PLASTIC FORKS in it!!
Now I'm concentrating on a specific tank battle toward the end of World War II!
Now I'm having INSIPID THOUGHTS about the beatiful, round wives of HOLLYWOOD MOVIE MOGULS encased in PLEXIGLASS CARS and being approached by SMALL BOYS selling FRUIT ...
Now KEN and BARBIE are PERMANENTLY ADDICTED to MIND-ALTERING DRUGS ...
Now my EMOTIONAL RESOURCES are heavily committed to 23% of the SMELTING and REFINING industry of the state of NEVADA!!
Now that I have my "APPLE", I comprehend COST ACCOUNTING!!
Now, let's SEND OUT for QUICHE!!
Of course, you UNDERSTAND about the PLAIDS in the SPIN CYCLE --
Oh my GOD -- the SUN just fell into YANKEE STADIUM!!
Oh, I get it!!  "The BEACH goes on", huh, SONNY??
Okay ... I'm going home to write the "I HATE RUBIK's CUBE HANDBOOK FOR DEAD CAT LOVERS" ...
OKAY!!  Turn on the sound ONLY for TRYNEL CARPETING, FULLY-EQUIPPED R.V.'S and FLOATATION SYSTEMS!!
OMNIVERSAL AWARENESS??  Oh, YEH!!  First you need four GALLONS of JELL-O and a BIG WRENCH!! ... I think you drop th'WRENCH in the JELL-O as if it was a FLAVOR, or an INGREDIENT ... ... or ... I ... um ... WHERE'S the WASHING MACHINES?
On SECOND thought, maybe I'll heat up some BAKED BEANS and watch REGIS PHILBIN ...  It's GREAT to be ALIVE!!
On the other hand, life can be an endless parade of TRANSSEXUAL
QUILTING BEES aboard a cruise ship to DISNEYWORLD if only we let it!!
On the road, ZIPPY is a pinhead without a purpose, but never without a POINT.
Once upon a time, four AMPHIBIOUS HOG CALLERS attacked a family of DEFENSELESS, SENSITIVE COIN COLLECTORS and brought DOWN their PROPERTY VALUES!!
Once, there was NO fun ... This was before MENU planning, FASHION statements or NAUTILUS equipment ... Then, in 1985 ... FUN was completely encoded in this tiny MICROCHIP ... It contain 14,768 vaguely amusing SIT-COM pilots!!  We had to wait FOUR BILLION years but we finally got JERRY LEWIS, MTV and a large selection of creme-filled snack cakes!
One FISHWICH coming up!!
ONE LIFE TO LIVE for ALL MY CHILDREN in ANOTHER WORLD all THE DAYS OF OUR LIVES.
ONE: I will donate my entire "BABY HUEY" comic book collection to the downtown PLASMA CENTER ... TWO: I won't START a BAND called "KHADAFY & THE HIT SQUAD" ... THREE: I won't ever TUMBLE DRY my FOX TERRIER again!!
... or were you driving the PONTIAC that HONKED at me in MIAMI last Tuesday?
Our father who art in heaven ... I sincerely pray that SOMEBODY at this table will PAY for my SHREDDED WHAT and ENGLISH MUFFIN ... and also leave a GENEROUS TIP ....
over in west Philadelphia a puppy is vomiting ...
OVER the underpass!  UNDER the overpass!  Around the FUTURE and BEYOND REPAIR!!
PARDON me, am I speaking ENGLISH?
Pardon me, but do you know what it means to be TRULY ONE with your BOOTH!
PEGGY FLEMMING is stealing BASKET BALLS to feed the babies in VERMONT.
People humiliating a salami!
PIZZA!!
Place me on a BUFFER counter while you BELITTLE several BELLHOPS in the Trianon Room!!  Let me one of your SUBSIDIARIES!
Please come home with me ... I have Tylenol!!
Psychoanalysis??  I thought this was a nude rap session!!!
PUNK ROCK!!  DISCO DUCK!!  BIRTH CONTROL!!
Quick, sing me the BUDAPEST NATIONAL ANTHEM!!
RELATIVES!!
Remember, in 2039, MOUSSE & PASTA will be available ONLY by prescription!!
RHAPSODY in Glue!
SANTA CLAUS comes down a FIRE ESCAPE wearing bright blue LEG WARMERS ... He scrubs the POPE with a mild soap or detergent for 15 minutes, starring JANE FONDA!!
Send your questions to ``ASK ZIPPY'', Box 40474, San Francisco, CA 94140, USA
SHHHH!!  I hear SIX TATTOOED TRUCK-DRIVERS tossing ENGINE BLOCKS into empty OIL DRUMS ...
Should I do my BOBBIE VINTON medley?
Should I get locked in the PRINCICAL'S OFFICE today -- or have a VASECTOMY??
Should I start with the time I SWITCHED personalities with a BEATNIK hair stylist or my failure to refer five TEENAGERS to a good OCULIST? Sign my PETITION.
So this is what it feels like to be potato salad
So, if we convert SUPPLY-SIDE SOYABEAN FUTURES into HIGH-YIELD T-BILL INDICATORS, the PRE-INFLATIONARY risks will DWINDLE to a rate of 2 SHOPPING SPREES per EGGPLANT!!
Someone in DAYTON, Ohio is selling USED CARPETS to a SERBO-CROATIAN
Sometime in 1993 NANCY SINATRA will lead a BLOODLESS COUP on GUAM!!
Somewhere in DOWNTOWN BURBANK a prostitute is OVERCOOKING a LAMB CHOP!!
Somewhere in suburban Honolulu, an unemployed bellhop is whipping up a batch of illegal psilocybin chop suey!!
Somewhere in Tenafly, New Jersey, a chiropractor is viewing "Leave it
to Beaver"!
Spreading peanut butter reminds me of opera!!  I wonder why?
TAILFINS!! ... click ... Talking Pinhead Blues: Oh, I LOST my ``HELLO KITTY'' DOLL and I get BAD reception on channel TWENTY-SIX!!
Th'HOSTESS FACTORY is closin' down and I just heard ZASU PITTS has been DEAD for YEARS..  (sniff)
My PLATFORM SHOE collection was CHEWED up by th' dog, ALEXANDER HAIG  won't let me take a SHOWER 'til Easter ... (snurf)
So I went to the kitchen, but WALNUT PANELING whup me upside mah HAID!!  (on no, no, no..  Heh, heh)
TAPPING?  You POLITICIANS!  Don't you realize that the END of the "Wash Cycle" is a TREASURED MOMENT for most people?!
Tex SEX!  The HOME of WHEELS!  The dripping of COFFEE!!  Take me to Minnesota but don't EMBARRASS me!!
Th' MIND is the Pizza Palace of th' SOUL
Thank god!! ... It's HENNY YOUNGMAN!!
The appreciation of the average visual graphisticator alone is worth
the whole suaveness and decadence which abounds!!
The entire CHINESE WOMEN'S VOLLEYBALL TEAM all share ONE personality -- and have since BIRTH!!
The fact that 47 PEOPLE are yelling and sweat is cascading down my SPINAL COLUMN is fairly enjoyable!!
The FALAFEL SANDWICH lands on my HEAD and I become a VEGETARIAN ...
... the HIGHWAY is made out of LIME JELLO and my HONDA is a barbequeued OYSTER!  Yum!
The Korean War must have been fun. ... the MYSTERIANS are in here with my CORDUROY SOAP DISH!!
The Osmonds!  You are all Osmonds!!  Throwing up on a freeway at dawn!!!
The PILLSBURY DOUGHBOY is CRYING for an END to BURT REYNOLDS movies!!
The PINK SOCKS were ORIGINALLY from 1952!!  But they went to MARS around 1953!!
The SAME WAVE keeps coming in and COLLAPSING like a rayon MUU-MUU ...
There is no TRUTH.  There is no REALITY.  There is no CONSISTENCY.
There are no ABSOLUTE STATEMENTS.   I'm very probably wrong.
There's a little picture of ED MCMAHON doing BAD THINGS to JOAN RIVERS in a $200,000 MALIBU BEACH HOUSE!!
There's enough money here to buy 5000 cans of Noodle-Roni! "These are DARK TIMES for all mankind's HIGHEST VALUES!" "These are DARK TIMES for FREEDOM and PROSPERITY!" "These are GREAT TIMES to put your money on BAD GUY to kick the CRAP out of MEGATON MAN!"
These PRESERVES should be FORCE-FED to PENTAGON OFFICIALS!!
They collapsed ... like nuns in the street ... they had no teen appeal!
This ASEXUAL PIG really BOILS my BLOOD ... He's so ... so ... URGENT!!
"This is a job for BOB VIOLENCE and SCUM, the INCREDIBLY STUPID MUTANT DOG." -- Bob Violence
This is a NO-FRILLS flight -- hold th' CANADIAN BACON!!
This MUST be a good party -- My RIB CAGE is being painfully pressed up against someone's MARTINI!! ... this must be what it's like to be a COLLEGE GRADUATE!!
This PIZZA symbolizes my COMPLETE EMOTIONAL RECOVERY!!
This PORCUPINE knows his ZIPCODE ... And he has "VISA"!!
This TOPS OFF my partygoing experience!  Someone I DON'T LIKE is talking to me about a HEART-WARMING European film ...
Those aren't WINOS -- that's my JUGGLER, my AERIALIST, my SWORD
SWALLOWER, and my LATEX NOVELTY SUPPLIER!!
Thousands of days of civilians ... have produced a ... feeling for the aesthetic modules --
Today, THREE WINOS from DETROIT sold me a framed photo of TAB HUNTER before his MAKEOVER!
Toes, knees, NIPPLES.  Toes, knees, nipples, KNUCKLES ... Nipples, dimples, knuckles, NICKLES, wrinkles, pimples!! TONY RANDALL!  Is YOUR life a PATIO of FUN??
Uh-oh -- WHY am I suddenly thinking of a VENERABLE religious leader frolicking on a FORT LAUDERDALE weekend?
Uh-oh!!  I forgot to submit to COMPULSORY URINALYSIS!
UH-OH!!  I put on "GREAT HEAD-ON TRAIN COLLISIONS of the 50's" by mistake!!!
UH-OH!!  I think KEN is OVER-DUE on his R.V. PAYMENTS and HE'S having a NERVOUS BREAKDOWN too!!  Ha ha.
Uh-oh!!  I'm having TOO MUCH FUN!!
UH-OH!!  We're out of AUTOMOBILE PARTS and RUBBER GOODS!
Used staples are good with SOY SAUCE!
VICARIOUSLY experience some reason to LIVE!!
Vote for ME -- I'm well-tapered, half-cocked, ill-conceived and TAX-DEFERRED!
Wait ... is this a FUN THING or the END of LIFE in Petticoat Junction??
Was my SOY LOAF left out in th'RAIN?  It tastes REAL GOOD!!
We are now enjoying total mutual interaction in an imaginary hot tub ...
We have DIFFERENT amounts of HAIR --
We just joined the civil hair patrol!
We place two copies of PEOPLE magazine in a DARK, HUMID mobile home. 45 minutes later CYNDI LAUPER emerges wearing a BIRD CAGE on her head!
Well, here I am in AMERICA..  I LIKE it.  I HATE it.  I LIKE it.  I
HATE it.  I LIKE it.  I HATE it.  I LIKE it.  I HATE it.  I LIKE ... EMOTIONS are SWEEPING over me!!
Well, I'm a classic ANAL RETENTIVE!!  And I'm looking for a way to VICARIOUSLY experience some reason to LIVE!!
Well, I'm INVISIBLE AGAIN ... I might as well pay a visit to the LADIES  ROOM ...
Well, O.K.  I'll compromise with my principles because of EXISTENTIAL DESPAIR!
Were these parsnips CORRECTLY MARINATED in TACO SAUCE?
What a COINCIDENCE!  I'm an authorized "SNOOTS OF THE STARS" dealer!!
What GOOD is a CARDBOARD suitcase ANYWAY?
What I need is a MATURE RELATIONSHIP with a FLOPPY DISK ...
What I want to find out is -- do parrots know much about Astro-Turf?
What PROGRAM are they watching?
What UNIVERSE is this, please??
What's the MATTER Sid? ... Is your BEVERAGE unsatisfactory?
When I met th'POPE back in '58, I scrubbed him with a MILD SOAP or DETERGENT for 15 minutes.  He seemed to enjoy it ...
When this load is DONE I think I'll wash it AGAIN ...
When you get your PH.D. will you get able to work at BURGER KING?
When you said "HEAVILY FORESTED" it reminded me of an overdue CLEANING
BILL ... Don't you SEE?  O'Grogan SWALLOWED a VALUABLE COIN COLLECTION and HAD to murder the ONLY MAN who KNEW!!
Where do your SOCKS go when you lose them in th' WASHER?
Where does it go when you flush?
Where's SANDY DUNCAN?
Where's th' DAFFY DUCK EXHIBIT??
Where's the Coke machine?  Tell me a joke!!
While my BRAINPAN is being refused service in BURGER KING, Jesuit priests are DATING CAREER DIPLOMATS!!
While you're chewing, think of STEVEN SPIELBERG'S bank account ...  his will have the same effect as two "STARCH BLOCKERS"!
WHO sees a BEACH BUNNY sobbing on a SHAG RUG?!
WHOA!!  Ken and Barbie are having TOO MUCH FUN!!  It must be the NEGATIVE IONS!!
Why are these athletic shoe salesmen following me??
Why don't you ever enter any CONTESTS, Marvin??  Don't you know your own ZIPCODE?
Why is everything made of Lycra Spandex?
Why is it that when you DIE, you can't take your HOME ENTERTAINMENT CENTER with you??
Will it improve my CASH FLOW?
Will the third world war keep "Bosom Buddies" off the air?
Will this never-ending series of PLEASURABLE EVENTS never cease?
With YOU, I can be MYSELF ...  We don't NEED Dan Rather ...
World War III?  No thanks!
World War Three can be averted by adherence to a strictly enforced dress code!
Wow!  Look!!  A stray meatball!!  Let's interview it!
Xerox your lunch and file it under "sex offenders"!
Yes, but will I see the EASTER BUNNY in skintight leather at an IRON MAIDEN concert?
You can't hurt me!!  I have an ASSUMABLE MORTGAGE!!
You mean now I can SHOOT YOU in the back and further BLUR th' distinction between FANTASY and REALITY?
You mean you don't want to watch WRESTLING from ATLANTA?
YOU PICKED KARL MALDEN'S NOSE!!
You should all JUMP UP AND DOWN for TWO HOURS while I decide on a NEW CAREER!!
You were s'posed to laugh!
YOU!!  Give me the CUTEST, PINKEST, most charming little VICTORIAN DOLLHOUSE you can find!!  An make it SNAPPY!!
Your CHEEKS sit like twin NECTARINES above a MOUTH that knows no BOUNDS -- Youth of today!  Join me in a mass rally for traditional mental attitudes!
Yow!
Yow!  Am I having fun yet?
Yow!  Am I in Milwaukee?
Yow!  And then we could sit on the hoods of cars at stop lights!
Yow!  Are we laid back yet?
Yow!  Are we wet yet?
Yow!  Are you the self-frying president?
Yow!  Did something bad happen or am I in a drive-in movie??
Yow!  I just went below the poverty line!
Yow!  I threw up on my window!
Yow!  I want my nose in lights!
Yow!  I want to mail a bronzed artichoke to Nicaragua!
Yow!  I'm having a quadrophonic sensation of two winos alone in a steel mill!
Yow!  I'm imagining a surfer van filled with soy sauce!
Yow!  Is my fallout shelter termite proof?
Yow!  Is this sexual intercourse yet??  Is it, huh, is it??
Yow!  It's a hole all the way to downtown Burbank!
Yow!  It's some people inside the wall!  This is better than mopping!
Yow!  Maybe I should have asked for my Neutron Bomb in PAISLEY --
Yow!  Now I get to think about all the BAD THINGS I did to a BOWLING BALL when I was in JUNIOR HIGH SCHOOL!
Yow!  Now we can become alcoholics!
Yow!  Those people look exactly like Donnie and Marie Osmond!!
Yow!  We're going to a new disco!
YOW!!  Everybody out of the GENETIC POOL!
YOW!!  I'm in a very clever and adorable INSANE ASYLUM!!
YOW!!  Now I understand advanced MICROBIOLOGY and th' new TAX REFORM laws!!
YOW!!  The land of the rising SONY!!
YOW!!  Up ahead!  It's a DONUT HUT!!
YOW!!  What should the entire human race DO??  Consume a fifth of
CHIVAS REGAL, ski NUDE down MT. EVEREST, and have a wild SEX WEEKEND!
YOW!!!  I am having fun!!!
Zippy's brain cells are straining to bridge synapses ...
