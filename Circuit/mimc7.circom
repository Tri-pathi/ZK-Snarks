pragma circom 2.0.0;

template MiMC7() {
   signal input iL;
    signal input iR;
    signal input k;

    signal output oL;
    signal output oR;

    var nRounds = 20;

    var c[20] = [
        0,
        15094701712633979350099012269393030856281085401958109394300330875807369155500,
        58822117991709291399958584587878890173462447340810934202916284361020530230644,
        44972321657656701396217128359747377944907050389224098353646131251687892523485,
        96493692533583833094972792594000734718199102111215539717208511322907796674014,
        23666743410824623558636227204903757801699474224294883946610526501881435075378,
        7631509229286711799753025145486014303456800393830722922398447708677119956535,
        73741498870852632128726731486779850740677996774410651950633444069957752439295,
        21476159689809443072097479095588538167124461464465789712443758461766119114744,
        39978761942792309329744876719073439260589034296437776211419688635522452659997,
        25161436470718351277017231215227846535148280460947816286575563945185127975034,
        90370030464179443930112165274275271350651484239155016554738639197417116558730,
        92014788260850167582827910417652439562305280453223492851660096740204889381255,
        40376490640073034398204558905403523738912091909516510156577526370637723469243,
        23701404396950336716716773711829949011495811533827229680198698317488498185005,
        112203415202699791888928570309186854585561656615192232544262649073999791317171,
        114801681136748880679062548782792743842998635558909635247841799223004802934045,
        4118229206495460255026732648766161713581908667345528627339812267008943723621,
        98844069804327418719255803021205697862031345913929363103790182598385469450387,
        4011925251638142722424298635980231878892077318587886982666459906440490374444
    ];

    signal lastOutputL[nRounds + 1];
    signal lastOutputR[nRounds + 1];

    var base[nRounds];
    signal base2[nRounds];
    signal base4[nRounds];
    signal base6[nRounds];

    lastOutputL[0] <== iL;
    lastOutputR[0] <== iR;

    for(var i = 0; i < nRounds; i++){
        base[i] = lastOutputR[i] + k + c[i];
        base2[i] <== base[i] * base[i];
        base4[i] <== base2[i] * base2[i];
        base6[i] <== base2[i] * base4[i];

        lastOutputR[i + 1] <== lastOutputL[i] + base6[i] * base[i];
        lastOutputL[i + 1] <== lastOutputR[i];
    }

    oL <== lastOutputL[nRounds];
    oR <== lastOutputR[nRounds];
}



template MiMC7Sponge(nInputs) {
    signal input k;
    signal input ins[nInputs];
    signal output o;

    signal lastR[nInputs + 1];
    signal lastC[nInputs + 1];

    lastR[0] <== 0;
    lastC[0] <== 0;

    component layers[nInputs];

    for(var i = 0; i < nInputs; i++){
        layers[i] = MiMC7();

        layers[i].iL <== lastR[i] + ins[i];
        layers[i].iR <== lastC[i];
        layers[i].k <== k;

        lastR[i + 1] <== layers[i].oL;
        lastC[i + 1] <== layers[i].oR;
    }

    o <== lastR[nInputs];
}

