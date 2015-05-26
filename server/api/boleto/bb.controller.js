'use strict';

var codigoBanco = "001";

exports.index = function(req, res) {
    var dadosBoleto = {
        diasPrazoPagamento: req.body.diasPrazoPagamento,
        taxaBoleto: req.body.taxaBoleto,
        valorCobrado: req.body.valorCobrado
    }
    console.log(dadosBoleto);
    var dados = getDados(dadosBoleto);
    //if(err) return res.send(500, err);
    res.json(200, dados);
};

var getDados = function(dadosBoleto) {

    var valorBoleto = dadosBoleto.valorCobrado + dadosBoleto.taxaBoleto;

    var dataVencimento = addDays(new Date(), dadosBoleto.diasPrazoPagamento);
    //var valorCobrado = dadosBoleto.valorCobrado.replace(",", ".");
    var valorBoleto = numberFormat(valorBoleto, 2, ',', '');

    return {
        codigoBanco: codigoBanco,
        codigoBancoComDv: geraCodigoBanco(codigoBanco),
        numMoeda: "9",
        fatorVencimento: fatorVencimento(dataVencimento),
        valor: formataNumero(valorBoleto, 10, 0, "valor"),
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
}

var modulo_11 = function(num, base, r) {
    var soma = getValorSoma(num, base);
    if (r == 0) {
        return getDigitoVerificador(num, soma);
    } else if (r == 1) {
        return soma % 11;
    }
}

var getValorSoma = function(num, base) {
    var soma = 0;
    var fator = 2;
    var numeros = [];
    var parcial = [];
    for (var i = num.length; i > 0; i--) {
        numeros[i] = num.substring(i - 1, 1);
        parcial[i] = numeros[i] * fator;
        soma += parcial[i];
        if (fator == base) {
            fator = 1;
        }
        fator++;
    }
    return soma;
}

var getDigitoVerificador = function(num, soma) {
    soma *= 10;
    var digito = soma % 11;
    if (digito == 10) {
        digito = "X";
    }
    if (num.length == "43") {
        if (digito == "0" || digito == "X" || digito > 9) {
            digito = 1;
        }
    }
    return digito;

}

var geraCodigoBanco = function(numero) {
    var parte1 = numero.substring(0, 3);
    var parte2 = modulo_11(parte1, 9, 0);
    return parte1 + "-" + parte2;
}

// VALOR

var formataNumero = function(numero, loop, insert, tipo) {
    if (tipo === "geral") {
        numero = numero.toString().replace(",", "");
        while (numero.length < loop) {
            numero = insert + numero;
        }
    }
    if (tipo === "valor") {
        numero = numero.toString().replace(",", "");
        while (numero.length < loop) {
            numero = insert + numero;
        }
    }
    if (tipo == "convenio") {
        while (numero.length < loop) {
            numero = insert + numero;
        }
    }
    return numero;
}

var numberFormat = function(numero, decimal, decimal_separador, milhar_separador) {
    numero = (numero + '').replace(/[^0-9+\-Ee.]/g, '');
    var n = !isFinite(+numero) ? 0 : +numero,
        prec = !isFinite(+decimal) ? 0 : Math.abs(decimal),
        sep = (typeof milhar_separador === 'undefined') ? ',' : milhar_separador,
        dec = (typeof decimal_separador === 'undefined') ? '.' : decimal_separador,
        s = '',
        toFixedFix = function(n, prec) {
            var k = Math.pow(10, prec);
            return '' + Math.round(n * k) / k;
        };
    s = (prec ? toFixedFix(n, prec) : '' + Math.round(n)).split('.');
    if (s[0].length > 3) {
        s[0] = s[0].replace(/\B(?=(?:\d{3})+(?!\d))/g, sep);
    }
    if ((s[1] || '').length < prec) {
        s[1] = s[1] || '';
        s[1] += new Array(prec - s[1].length + 1).join('0');
    }

    return s.join(dec);
}


// DATES

var addDays = function(date, days) {
    return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

var fatorVencimento = function(data) {
    console.log(data);
    var ano = data.getFullYear();
    var mes = data.getMonth();
    var dia = data.getDate();
    return (Math.abs((dateToDays("1997", "10", "07")) - (dateToDays(ano, mes, dia))));
}

var dateToDays = function(year, month, day) {
    var century = year.toString().substring(0, 2);
    year = year.toString().substring(2, 2);
    if (month > 2) {
        month -= 3;
    } else {
        month += 9;
        if (year) {
            year--;
        } else {
            year = 99;
            century--;
        }
    }
    var centuryFloor = Math.floor((146097 * century) / 4);
    var yearFloor = Math.floor((1461 * year) / 4);
    var monthFloor = Math.floor((153 * month + 2) / 5);
    return (centuryFloor + yearFloor + monthFloor + day + 1721119);
}
