pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
// Grand Mastermind variation
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


template CountPegs(){
    signal input solnColor[5];
    signal input guessColor[5];
    signal input solnShape[5];
    signal input guessShape[5];

    signal output numBlacks;
    signal output numWhites; 
    signal output numBlues;

    var Blacks = 1;
    var Whites = 2;
    var Blues = 3;
    var None = 0;
    var colors[25];
    component equalBWB[50];

    for (var j=0; j<5; j++) {
        for (var k=0; k<5; k++) {
            equalBWB[5*j+k] = IsEqual();
            equalBWB[5*j+k].in[0] <== solnColor[j];
            equalBWB[5*j+k].in[1] <== guessColor[k];

            equalBWB[25+5*j+k] = IsEqual();
            equalBWB[25+5*j+k].in[0] <== solnShape[j];
            equalBWB[25+5*j+k].in[1] <== guessShape[k];

            if(equalBWB[5*j+k].out && equalBWB[25+5*j+k].out && j==k){
                colors[5*j+k] = Blacks;
            } else{
                if(equalBWB[5*j+k].out && equalBWB[25+5*j+k].out && colors[5*j+k] != Blacks){
                    colors[5*j+k] = Whites;
                } else{
                    if((equalBWB[5*j+k].out || equalBWB[25+5*j+k].out) && colors[5*j+k] == None){
                       colors[5*j+k] = Blues;
                    }
                }
            }
        }
    }

    var res = 4;
    var intBlacks = 0;
    var intWhites = 0;
    var intBlues = 0;
    component equalColors[75];

    for(var index = 0; index<25; index++){
        //TODO - here makes each intvar as a variable holding a signal sum where
        // each signal can take 0 to 1 values. use equal component for this
        equalColors[index] = IsEqual();
        equalColors[index].in[0] <== colors[index];
        equalColors[index].in[1] <== Blacks;
        intBlacks += equalColors[index].out;

        equalColors[25+index] = IsEqual();
        equalColors[25+index].in[0] <== colors[index];
        equalColors[25+index].in[1] <== Whites;
        intWhites += equalColors[25+index].out;

        equalColors[50+index] = IsEqual();
        equalColors[50+index].in[0] <== colors[index];
        equalColors[50+index].in[1] <== Blues;
        intBlues += equalColors[50+index].out;
    }
    //TODO - here use greather equal component, ternary assignament operator
    if(intBlacks>=res){
        numBlacks <== res;
    } else{
        numBlacks <== intBlacks;
        res -= numBlacks;
        if(intWhites>=res){
            numWhites <== res;
        }else{
            numWhites <== intWhites;
            res -= numWhites;
            if(intBlues>=res){
                numBlues <== res;
            }else{
                numBlues <== intBlues;
                res -= numBlues;
            }
        }
    }

}

template MastermindVariation() {
    // Public inputs
    signal input pubGuessColorA;
    signal input pubGuessColorB;
    signal input pubGuessColorC;
    signal input pubGuessColorD;
    signal input pubGuessColorE;
    signal input pubGuessShapeA;
    signal input pubGuessShapeB;
    signal input pubGuessShapeC;
    signal input pubGuessShapeD;
    signal input pubGuessShapeE;
    signal input pubNumBlacks;
    signal input pubNumWhites;
    signal input pubNumBlues;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnColorA;
    signal input privSolnColorB;
    signal input privSolnColorC;
    signal input privSolnColorD;
    signal input privSolnColorE;
    signal input privSolnShapeA;
    signal input privSolnShapeB;
    signal input privSolnShapeC;
    signal input privSolnShapeD;
    signal input privSolnShapeE;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    //TODO - extract this to a template
    //NOTE - contraint to pubNumBlacks+pubNumWhites+pubNumBlues<=4
    component lessThanFour = LessThan(3);
    signal interBlackWhitesPegSum <== pubNumBlacks + pubNumWhites;
    lessThanFour.in[0] <== interBlackWhitesPegSum + pubNumBlues;
    lessThanFour.in[1] <== 5;
    lessThanFour.out === 1;
    //TODO - extract this to a template
    var guessColor[5] = [
        pubGuessColorA, 
        pubGuessColorB, 
        pubGuessColorC, 
        pubGuessColorD, 
        pubGuessColorE
    ];
    var guessShape[5] = [
        pubGuessShapeA,
        pubGuessShapeB,
        pubGuessShapeC,
        pubGuessShapeD,
        pubGuessShapeE
    ];
    var solnColor[5] =  [
        privSolnColorA,
        privSolnColorB,
        privSolnColorC,
        privSolnColorD,
        privSolnColorE
    ];  
    var solnShape[5] =  [
        privSolnShapeA,
        privSolnShapeB,
        privSolnShapeC,
        privSolnShapeD,
        privSolnShapeE
    ];  
    var j = 0;
    var k = 0;
    component lessThan[20];
    // component equalGuess[6];
    // component equalSoln[6];
    // var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 5.
    for (j=0; j<5; j++) {
        //TODO - use a cicle to unroll this
        lessThan[j] = LessThan(3);
        lessThan[j].in[0] <== guessColor[j];
        lessThan[j].in[1] <== 5;
        lessThan[j].out === 1;
        
        lessThan[j+5] = LessThan(3);
        lessThan[j+5].in[0] <== guessShape[j];
        lessThan[j+5].in[1] <== 5;
        lessThan[j+5].out === 1;
        
        lessThan[j+10] = LessThan(3);
        lessThan[j+10].in[0] <== solnColor[j];
        lessThan[j+10].in[1] <== 5;
        lessThan[j+10].out === 1;

        lessThan[j+15] = LessThan(3);
        lessThan[j+15].in[0] <== solnShape[j];
        lessThan[j+15].in[1] <== 5;
        lessThan[j+15].out === 1;
    }

    // Count blacks & whites & blues
    component countPegs = CountPegs();
    countPegs.guessColor <== guessColor;
    countPegs.solnColor <== solnColor;
    countPegs.guessShape <== guessShape;
    countPegs.solnShape <== solnShape;

    signal numBlacks <== countPegs.numBlacks;
    signal numWhites <== countPegs.numWhites;
    signal numBlues <== countPegs.numBlues;

    component equalAssertion[3];
    var colorAssertionCounted[3] = [numBlacks, numWhites, numBlues];
    var colorAssertionPub[3] = [pubNumBlacks, pubNumWhites, pubNumBlues];

    for(var index=0; index<3; index++){
        equalAssertion[index] = IsEqual();
        equalAssertion[index].in[0] <== colorAssertionCounted[index];
        equalAssertion[index].in[1] <== colorAssertionPub[index];
        equalAssertion[index].out === 1;
    }

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(11);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnColorA;
    poseidon.inputs[2] <== privSolnColorB;
    poseidon.inputs[3] <== privSolnColorC;
    poseidon.inputs[4] <== privSolnColorD;
    poseidon.inputs[5] <== privSolnColorE;
    poseidon.inputs[6] <== privSolnShapeA;
    poseidon.inputs[7] <== privSolnShapeB;
    poseidon.inputs[8] <== privSolnShapeC;
    poseidon.inputs[9] <== privSolnShapeD;
    poseidon.inputs[10] <== privSolnShapeE;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
 }

component main {public [pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessColorD, pubGuessColorE, pubGuessShapeA, pubGuessShapeB, pubGuessShapeC, pubGuessShapeD, pubGuessShapeE, pubNumBlacks, pubNumWhites, pubNumBlues, pubSolnHash]} = MastermindVariation();