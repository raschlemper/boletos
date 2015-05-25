'use strict';

exports.index = function(req, res) {

    var dados = {

        codigobanco: "001",
        codigoBancoComDv: null, // geraCodigoBanco(codigobanco),
        numMoeda: "9",
        fatorVencimento: null, // fator_vencimento(dadosboleto["data_vencimento"]),
        //valor tem 10 digitos, sem virgula
        valor: null, // formata_numero(dadosboleto["valor_boleto"], 10, 0, "valor"),
        //agencia é sempre 4 digitos
        agencia: null, // formata_numero(dadosboleto["agencia"], 4, 0),
        //conta é sempre 8 digitos
        conta: null, // formata_numero(dadosboleto["conta"], 8, 0),
        //carteira 18
        carteira: null, // dadosboleto["carteira"],
        //agencia e conta
        agenciaCodigo: null, // agencia."-".modulo_11(agencia)." / ".conta."-".modulo_11(conta),
        //Zeros: usado quando convenio de 7 digitos
        livreZeros: '000000'
    };

    //if(err) return res.send(500, err);
    res.json(200, dados);

};
