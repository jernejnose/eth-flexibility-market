pragma solidity >=0.4.16 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract BcMarket {
    
    // naredimo generator IDjev, s uporabo counters.sol
    using Counters for Counters.Counter;
    Counters.Counter private idGenerator;
    
    // objekt fleksibilnostne ponudbe
    struct Ponudba {
        address payable ponudnik;
        uint cena;
        uint zacetek;
        uint konec;
        uint8 status; // 0 - aktivna, 1 - prodana, 2 - potrjena, 3 - preklicana
        uint cas_nakupa;
        uint id;
        address payable kupec;
        uint moc; // moc fleksibilnosti v kW
    }

    // seznam vseh ponudb
    mapping(uint256 => Ponudba) private seznamPonudb;

    // dogodek nova ponudba
    event novaPonudba (
        uint cena,
        uint idPonudbe,
        uint zacetek,
        uint konec,
        address ponudnik,
        uint8 status,
        uint moc // moc fleksibilnosti v kW
        );

    
    event ponudbaKupljena (
        uint idPonudbe,
        address ponudnik,
        uint zacetek,
        uint konec,
        uint moc
        );


    // funkcija za oddajo ponudbe
    function oddajPonudbo(uint cena, uint zacetek, uint konec, uint moc) public {
        // ponudba se mora zaceti v prihodnosti
        require(zacetek > block.timestamp, "zacetek mora biti v prihodnosti!");
        // ponudba se ne sme koncati pred zacetkom
        require(konec > zacetek, "a");
        uint idPonudbe = idGenerator.current();
        // ustvrimo novo ponudbo in jo dodamo na seznam
        seznamPonudb[idPonudbe] = Ponudba(payable(msg.sender), cena, zacetek, konec, 0, 0, idPonudbe, payable(address(0)), moc);
        //sprozimo event, da vidimo ponudbe v logih, tako tudi prodajalec izve idPonudbe
        emit novaPonudba(cena, idPonudbe, zacetek, konec, msg.sender, 0, moc);
        // povecamo id za ena
        idGenerator.increment();

    }

    // funkcija za nakup punudbe, eth se shrani v pogodbi, izvajalec sredstva dobi šele po dokazu
    function kupiPonudbo(uint idPonudbe) public payable {
        uint cena = seznamPonudb[idPonudbe].cena;
        require(msg.value == cena, "Placaj pravo ceno!");
        // spremenimo stanje ponudbe na prodano
        seznamPonudb[idPonudbe].status = 1;
        // shranimo naslov kupca ponudbe
        seznamPonudb[idPonudbe].kupec = payable(msg.sender);
        // shranimo cas nakupa
        seznamPonudb[idPonudbe].cas_nakupa = block.timestamp;
        // oddamo event, da ponudnik ve, da je bila kupljena
        emit ponudbaKupljena(idPonudbe, seznamPonudb[idPonudbe].ponudnik, seznamPonudb[idPonudbe].zacetek, seznamPonudb[idPonudbe].konec, seznamPonudb[idPonudbe].moc);
    }

    // funkcija za zahtevo placila
    function zahtevajPlacilo(uint idPonudbe /*, string memory dokaz */) public {
        require(block.timestamp > seznamPonudb[idPonudbe].konec, "Placilo lahko zahtevas sele po izteku ponudbe");
        require(seznamPonudb[idPonudbe].status == 1, "Ponudba se ni kupljena ali pa je ze placana");
        uint cena = seznamPonudb[idPonudbe].cena;
        // preverimo dokaz, uporabimo zunanji API. Pri preverjanju realizacije upostevamo cas nakupa
        // sredstva posljemo ponudniku
        (bool success, ) = seznamPonudb[idPonudbe].ponudnik.call{value: cena}("");
        require(success, "Failed to send Ether");
        seznamPonudb[idPonudbe].status = 2;

    }

    function vrniVsePonudbe() public view returns (Ponudba[] memory) {
        uint steviloPonudb = idGenerator.current();

        // naredimo seznam, v katerega bomo kopirali podatke o ponudbah
        Ponudba[] memory ponudbe = new Ponudba[](steviloPonudb);
        
        for (uint i = 0; i < steviloPonudb; i++) {
            Ponudba storage itaPonudba = seznamPonudb[i];
            ponudbe[i] = itaPonudba;

        }

        return ponudbe;
    }

}





