-- Projekt: uczelnia wyzsza w Polsce. MySQL 8.0.16+ (egzekwowane CHECK).
-- Wylacznie DDL: bez danych testowych, widokow, triggerow i procedur.
-- Model dotyczy jednej uczelni; funkcja opisuje aktualne stanowiska
-- (np. rektor, dziekan). Nie modelujemy osobno wydzialow ani historii funkcji.
-- Pracownicy w tym wycinku sa dydaktykami i moga pelnic funkcje kierownicze.
-- Jeden student nalezy do jednej grupy w danym semestrze.
-- Jedne zajecia = jeden przedmiot dla grupy w semestrze, jeden prowadzacy.
-- Jeden zapis ma wiele ocen czastkowych i najwyzej jedna aktualna koncowa.
-- Brak historii poprawek oceny koncowej. Skala ocen: 2, 3, 3.5, 4, 4.5, 5.
-- PESEL i NRB: sprawdzany format, bez kontroli sum kontrolnych.
-- Co najmniej jedno przypisanie kazdego studenta do grupy zapewnia proces
-- rejestracji w aplikacji; FK/UNIQUE zapewniaja poprawnosc istniejacych przypisan.
SET sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
CREATE SCHEMA IF NOT EXISTS wsb_db DEFAULT CHARACTER SET utf8mb4;
USE wsb_db;

CREATE TABLE uczelnia (
    uczelnia_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nazwa VARCHAR(200) NOT NULL,
    ulica_i_numer VARCHAR(150) NOT NULL,
    kod_pocztowy VARCHAR(10) NOT NULL,
    miejscowosc VARCHAR(100) NOT NULL,
    telefon VARCHAR(25) NOT NULL,
    email VARCHAR(254) NOT NULL,
    sekretariat_telefon VARCHAR(25) NOT NULL,
    sekretariat_email VARCHAR(254) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pracownik (
    pracownik_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uczelnia_id INT NOT NULL,
    imie VARCHAR(60) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    plec CHAR(1) NOT NULL,
    pesel CHAR(11) NOT NULL UNIQUE,
    telefon VARCHAR(25) NOT NULL,
    adres_zamieszkania VARCHAR(250) NOT NULL,
    data_zatrudnienia DATE NOT NULL,
    data_ustania DATE NULL,
    numer_konta CHAR(26) NOT NULL,
    FOREIGN KEY (uczelnia_id) REFERENCES uczelnia (uczelnia_id),
    CHECK (plec IN ('K','M')),
    CHECK (pesel REGEXP '^[0-9]{11}$'),
    CHECK (numer_konta REGEXP '^[0-9]{26}$'),
    CHECK (data_ustania IS NULL OR data_ustania >= data_zatrudnienia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE funkcja (
    funkcja_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nazwa VARCHAR(80) NOT NULL UNIQUE,
    pracownik_id INT NOT NULL,
    FOREIGN KEY (pracownik_id) REFERENCES pracownik (pracownik_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student (
    student_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nr_albumu VARCHAR(20) NOT NULL UNIQUE,
    imie VARCHAR(60) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    plec CHAR(1) NOT NULL,
    pesel CHAR(11) NOT NULL UNIQUE,
    data_urodzenia DATE NOT NULL,
    CHECK (plec IN ('K','M')),
    CHECK (pesel REGEXP '^[0-9]{11}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE grupa (
    grupa_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nazwa VARCHAR(50) NOT NULL,
    rocznik SMALLINT NOT NULL,
    opiekun_id INT NOT NULL,
    UNIQUE (nazwa, rocznik),
    FOREIGN KEY (opiekun_id) REFERENCES pracownik (pracownik_id),
    CHECK (rocznik BETWEEN 1900 AND 2200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE semestr (
    semestr_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    rok_rozpoczecia SMALLINT NOT NULL,
    rodzaj VARCHAR(6) NOT NULL,
    data_od DATE NOT NULL,
    data_do DATE NOT NULL,
    UNIQUE (rok_rozpoczecia, rodzaj),
    CHECK (rodzaj IN ('zimowy','letni')),
    CHECK (data_do >= data_od)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE przedmiot (
    przedmiot_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    kod VARCHAR(20) NOT NULL UNIQUE,
    nazwa VARCHAR(150) NOT NULL,
    opis TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE przynaleznosc (
    przynaleznosc_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    grupa_id INT NOT NULL,
    semestr_id INT NOT NULL,
    UNIQUE (student_id, semestr_id),
    UNIQUE (przynaleznosc_id, grupa_id, semestr_id),
    FOREIGN KEY (student_id) REFERENCES student (student_id),
    FOREIGN KEY (grupa_id) REFERENCES grupa (grupa_id),
    FOREIGN KEY (semestr_id) REFERENCES semestr (semestr_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE zajecia (
    zajecia_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    przedmiot_id INT NOT NULL,
    grupa_id INT NOT NULL,
    semestr_id INT NOT NULL,
    prowadzacy_id INT NOT NULL,
    UNIQUE (przedmiot_id, grupa_id, semestr_id),
    UNIQUE (zajecia_id, grupa_id, semestr_id),
    FOREIGN KEY (przedmiot_id) REFERENCES przedmiot (przedmiot_id),
    FOREIGN KEY (grupa_id) REFERENCES grupa (grupa_id),
    FOREIGN KEY (semestr_id) REFERENCES semestr (semestr_id),
    FOREIGN KEY (prowadzacy_id) REFERENCES pracownik (pracownik_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE zapis (
    zapis_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    przynaleznosc_id INT NOT NULL,
    zajecia_id INT NOT NULL,
    grupa_id INT NOT NULL,
    semestr_id INT NOT NULL,
    UNIQUE (przynaleznosc_id, zajecia_id),
    FOREIGN KEY (przynaleznosc_id, grupa_id, semestr_id) REFERENCES przynaleznosc (przynaleznosc_id, grupa_id, semestr_id),
    FOREIGN KEY (zajecia_id, grupa_id, semestr_id) REFERENCES zajecia (zajecia_id, grupa_id, semestr_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ocena_czastkowa (
    ocena_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    zapis_id INT NOT NULL,
    wartosc DECIMAL(2,1) NOT NULL,
    data_wystawienia DATE NOT NULL,
    opis VARCHAR(200) NOT NULL,
    FOREIGN KEY (zapis_id) REFERENCES zapis (zapis_id),
    CHECK (wartosc IN (2.0,3.0,3.5,4.0,4.5,5.0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ocena_koncowa (
    zapis_id INT NOT NULL PRIMARY KEY,
    wartosc DECIMAL(2,1) NOT NULL,
    data_wystawienia DATE NOT NULL,
    FOREIGN KEY (zapis_id) REFERENCES zapis (zapis_id),
    CHECK (wartosc IN (2.0,3.0,3.5,4.0,4.5,5.0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

