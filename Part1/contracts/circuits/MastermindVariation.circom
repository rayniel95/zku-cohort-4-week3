pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
// Grand Mastermind variation
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


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

        // for (k=j+1; k<4; k++) {
        //     // Create a constraint that the solution and guess digits are unique. no duplication.
        //     equalGuess[equalIdx] = IsEqual();
        //     equalGuess[equalIdx].in[0] <== guess[j];
        //     equalGuess[equalIdx].in[1] <== guess[k];
        //     equalGuess[equalIdx].out === 0;
        //     equalSoln[equalIdx] = IsEqual();
        //     equalSoln[equalIdx].in[0] <== soln[j];
        //     equalSoln[equalIdx].in[1] <== soln[k];
        //     equalSoln[equalIdx].out === 0;
        //     equalIdx += 1;
        // }
    }

    // Count blacks & whites & blues
    var Blacks = 1;
    var Whites = 2;
    var Blues = 3;
    var None = 0;
    var colors[25];
    component equalBWB[50];

    for (j=0; j<5; j++) {
        for (k=0; k<5; k++) {
            // equalHB[5*j+k] = IsEqual();
            // equalHB[5*j+k].in[0] <== soln[j];
            // equalHB[5*j+k].in[1] <== guess[k];

            // equalHB[10*j+k] = IsEqual();
            // equalHB[10*j+k].in[0] <== soln[j];
            // equalHB[10*j+k].in[1] <== guess[k];
            // whites += equalHB[4*j+k].out;
            // if (j == k) {
            //     blacks += equalHB[4*j+k].out;
            //     whites -= equalHB[4*j+k].out;
            // }

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

    var numBlacks;
    var numWhites; 
    var numBlues;
    var res = 4;
    var intBlacks;
    var intWhites;
    var intBlues;

    for(var index = 0; index<25; index++){
        if(colors[index]==Blacks){
            intBlacks++;
        }
        if(colors[index]==Whites){
            intWhites++;
        }
        if(colors[index]==Blues){
            intBlues++;
        }
    }
    if(intBlacks>=res){
        numBlacks=res;
    } else{
        numBlacks = intBlacks;
        res -= numBlacks;
        if(intWhites>=res){
            numWhites = res;
        }else{
            numWhites = intWhites;
            res -= numWhites;
            if(intBlues>=res){
                numBlues = res;
            }else{
                numBlues = intBlues;
                res -= numBlues;
            }
        }
    }

    component equalAssertion[3];
    var colorAssertionCounted[3] = [numBlacks, numWhites, numBlues];
    var colorAssertionPub[3] = [pubNumBlacks, pubNumWhites, pubNumBlues];

    for(var index=0; index<=3; index++){
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