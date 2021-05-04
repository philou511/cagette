package mangopay;

@:enum
abstract TransactionStatus(String) {
  var Created = "CREATED";
  var Succeeded = "SUCCEEDED";
  var Failed = "FAILED";
}

@:enum
abstract TransactionType(String) {
  var Payin = "PAYIN";
  var Transfer = "TRANSFER";
  var Payout = "PAYOUT";
}

@:enum
abstract Currency(String) {
  var Euro = "EUR"; 
}

@:enum
abstract LegalStatus(String) {
  	var Soletrader = "SOLETRADER";
	var Organization = "ORGANIZATION";
	var Business = "BUSINESS"; 
}

typedef NaturalUser = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	?PersonType: String,
	Email: String,
	?KYCLevel: String,
	FirstName: String,
	LastName: String,
	?Address: {
		AddressLine1: String,
		?AddressLine2: String,
		City: String,
		?Region: String,
		PostalCode: String,
		Country: String
	},
	Birthday: Float,
	Nationality: String,
	CountryOfResidence: String,
	?Occupation: String,
	?IncomeRange: Int,
	?ProofOfAddress: String,
    ?ProofOfIdentity: String,
	?Capacity: String,
	?errors: String
};

//@doc https://docs.mangopay.com/endpoints/v2.01/users#e259_create-a-legal-user
typedef LegalUser = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	?PersonType: String,//NATURAL or LEGAL
	Email: String,
	?KYCLevel: String,//LIGHT, REGULAR
	?HeadquartersAddress: {
		AddressLine1: String,
		?AddressLine2: String,
		City: String,
		?Region: String,
		PostalCode: String,
		Country: String
	},
	LegalPersonType: LegalStatus,//BUSINESS,ORGANIZATION,SOLETRADER
	Name: String,
	?LegalRepresentativeAddress: {
		AddressLine1: String,
		?AddressLine2: String,
		City: String,
		?Region: String,
		PostalCode: String,
		Country: String
	},
	LegalRepresentativeBirthday: Float,
	LegalRepresentativeCountryOfResidence: String,
	LegalRepresentativeNationality: String,
	?LegalRepresentativeEmail: String,
	LegalRepresentativeFirstName: String,
	LegalRepresentativeLastName: String,
	?LegalRepresentativeProofOfIdentity: String,
	?Statute: String,
	?ShareholderDeclaration: String,
	?ProofOfRegistration: String,
	?CompanyNumber: String
};

typedef Wallet = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	Owners: Array<Int>,
	?Balance:Money,
	?FundsType: String,
	Description: String,
	Currency: String
};
 
typedef CardWebPayIn = {
	?Id: String,
	?CreationDate: Float,
	?Tag: String,
	DebitedFunds	: Money,
	?CreditedFunds	: Money,
	Fees			: Money,
	?DebitedWalletId: Int,
	CreditedWalletId: Int,
	AuthorId: Int,
	?CreditedUserId: Int,
	?Nature: String,
	?Status: TransactionStatus,
	?ExecutionDate: Float,
	?ResultCode: String,
	?ResultMessage: String,
	?Type: String,
	?PaymentType: String,
	?ExecutionType: String,
	ReturnURL: String,
	CardType: String,
	?SecureMode: String,
	Culture: String,
	?TemplateURL: String,
	?StatementDescriptor: String,
	?RedirectURL: String
};

typedef Transaction = {
	Id: String,
	CreationDate: Float,
	Tag: String,
	DebitedFunds : Money,
	CreditedFunds: Money,
	Fees: Money,
	DebitedWalletId : Int,
	CreditedWalletId: Int,
	AuthorId: Int,
	CreditedUserId: Int,
	Nature : String,
	Status: TransactionStatus,
	ExecutionDate: Float,
	ResultCode : String,
	ResultMessage: String,
	Type: TransactionType
}

typedef Refund = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	?DebitedFunds:Money,
	?CreditedFunds:Money,
	?Fees:Money,
	?DebitedWalletId: Int,
	?CreditedWalletId: Int,
	AuthorId: Int,
	?CreditedUserId: Int,
	?Nature: String,
	?Status: String,
	?ExecutionDate: Float,
	?ResultCode: String,
	?ResultMessage: String,
	?Type: String,
	InitialTransactionId: Int,
	?InitialTransactionType: String,
	?RefundReason: {
		RefusedReasonType: String,
		RefusedReasonMessage: String
	}
};

typedef Transfer = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	DebitedFunds:Money,
	?CreditedFunds:Money,
	Fees: Money,
	DebitedWalletId: Int,
	CreditedWalletId: Int,
	AuthorId: Int,
	?CreditedUserId: Int,
	?Nature: String,
	?Status: TransactionStatus,
	?ExecutionDate: Float,
	?ResultCode: String,
	?ResultMessage: String,
	?Type: String
};

typedef IBANBankAccount = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	?Type: String,
	OwnerAddress: {
		AddressLine1: String,
		?AddressLine2: String,
		City: String,
		?Region: String,
		PostalCode: String,
		Country: String
	},
	OwnerName: String,
	?UserId: Int,
	?Active: Bool,
	IBAN: String,
	?BIC: String
};

typedef PayOut = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	DebitedFunds:Money,
	?CreditedFunds: Money,
	Fees: Money,
	DebitedWalletId: Int,
	?CreditedWalletId: Int,
	AuthorId: Int,
	?CreditedUserId: Int,
	?Nature: String,
	?Status: TransactionStatus,
	?ExecutionDate: Float,
	?ResultCode: String,
	?ResultMessage: String,
	?Type: String,
	BankAccountId: Int,
	BankWireRef: String,
	?PaymentType: String	
};

typedef KYCDocument = {
	?Id: Int,
	?CreationDate: Float,
	?Tag: String,
	?UserId: Int,
	Type: String,
	?Status: String,
	?RefusedReasonMessage: String,
	?RefusedReasonType: String,
	?ProcessedDate: Float
};

typedef Error = {
  Message: String,
  Type: String,
  Id: Int,
  Date: Float,
  errors: Dynamic,
  /*"errors" : {
    "Currency": "The code XPX cannot be found in the standard ISO 4217 : http://en.wikipedia.org/wiki/ISO_4217"
  }*/
};

typedef Money = {
	Currency : Currency,
	Amount : Int
}

typedef UBODeclaration = {
	Id : Int,
	UserId : Int,
	Status : String,
	Reason : String,
	Message : String,
	Ubos : Array<UBO>,
}

typedef UBO = {
	Id : Int,
	FirstName : String,
	LastName : String,
}
