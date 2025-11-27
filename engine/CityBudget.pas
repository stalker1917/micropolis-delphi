// This file is part of MicropolisJ.
// Copyright (C) 2013 Jason Long
// Portions Copyright (C) 1989-2007 Electronic Arts Inc.
//
// MicropolisJ is free software; you can redistribute it and/or modify
// it under the terms of the GNU GPLv3, with additional terms.
// See the README file, included in this distribution, for details.


unit CityBudget;

interface

//uses
  //Micropolis;

type
  TCityBudget = class
  //private
   // FCity: TMicropolis;
  public
    TotalFunds: Integer;         // Cash on hand
    TaxFund: Integer;            // Taxes collected this period (1/TAXFREQ units)
    RoadFundEscrow: Integer;     // Prepaid road maintenance
    FireFundEscrow: Integer;     // Prepaid fire maintenance
    PoliceFundEscrow: Integer;   // Prepaid police maintenance

    constructor Create;//(City: TMicropolis);
  end;

type
 TFinancialHistory = record
		cityTime: Integer;
		totalFunds: Integer;
		taxIncome: Integer;
		operatingExpenses: Integer;
  end;
implementation

{ TCityBudget }

constructor TCityBudget.Create();//City: TMicropolis);
begin
  inherited Create;
  //FCity := City;
end;




end.
