parser grammar C2105074Parser;

options {
    tokenVocab = C2105074Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
	#include <vector>
	#include <sstream>
    #include <cstdlib>
    #include "C2105074Lexer.h"
	#include "2105074_symbolTable.h"

    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;
	extern std::ofstream machineFilePart1;
	extern std::ofstream machineFilePart2;


    extern int syntaxErrorCount;
}

@parser::members {
	symbolTable symTable{7,false};
	std::string currentVarType; 
	std::vector<std::pair<std::string, std::string>> currentFunctionParams; 
	bool hasReturnValue = false; 
	std::string currentFunc;
	bool istermerror = false; 
	int offset=2;
	int localVarSpace=0;
	int currentFunctionParamCount=0;
    int level = 0;
	std::vector<std::string> exitlabels,elselabels;
	int loopcount = 0;
	vector<std::string> looplabels;
	vector<int >argcount;
	vector<int>incrementLabels;

    std::vector<std::string> split(const std::string& str, const std::string& delimiter) {
        std::vector<std::string> tokens;
        if (str.empty()) return tokens;
        
        size_t start = 0;
        size_t end = str.find(delimiter);
        
        while (end != std::string::npos) {
            tokens.push_back(str.substr(start, end - start));
            start = end + delimiter.length();
            end = str.find(delimiter, start);
        }
        tokens.push_back(str.substr(start));
        return tokens;
    }
    

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }
	void WriteMachine(const std::string message){
		if(!machineFilePart1){
			std::cout<<"Error opening machineFilePart1"<<std::endl;
			return;
		}
		machineFilePart1<<message<<std::endl;
		machineFilePart1.flush();

	}
	void WriteMachine2(const std::string message)
	{
		if (!machineFilePart2)
		{
			std::cout<<"Error opening machineFilePart2"<<std::endl;
			return ;
		}
		machineFilePart2<<message<<std::endl;
		machineFilePart2.flush();
	}

	void IntitalizeCode(){
		WriteMachine2(".MODEL SMALL\n.STACK 1000H\n.DATA\n\t\tnumber DB \"00000$\"");		
	}

	
	std::string trim(const std::string& str) {
		size_t start = str.find_first_not_of(" \t\r\n");
		if (start == std::string::npos) return "";
		size_t end = str.find_last_not_of(" \t\r\n");
		return str.substr(start, end - start + 1);
	}


    
    
    std::string getVariableType(const std::string& varName) {
        Symbolinfo* symbol = symTable.lookUp(varName);
        if (symbol) {
            return symbol->getType();
        }
        return "UNKNOWN";
    }
    
    
    std::string getArrayElementType(const std::string& varName) {
        Symbolinfo* symbol = symTable.lookUp(varName);
        if (symbol) {
            std::string type = symbol->getType();
            if (type == "INT_ARRAY") {
                return "INT";
            } else if (type == "FLOAT_ARRAY") {
                return "FLOAT";
            } else {
                return type; 
            }
        }
        return "UNKNOWN";
    }
    
    
    std::string inferExpressionType(const std::string& exprText) {
        
        if (exprText.find('.') != std::string::npos) {
            return "FLOAT";  
        }
    
        std::string tempExpr = exprText;
   
        std::string operators = "+-*/%()&|!<>=, ";
        for (char op : operators) {
            size_t pos = 0;
            while ((pos = tempExpr.find(op, pos)) != std::string::npos) {
                tempExpr[pos] = ' ';
                pos++;
            }
        }
        
        
        std::istringstream iss(tempExpr);
        std::string token;
        while (iss >> token) {
            
            if (token.find_first_not_of("0123456789") == std::string::npos) {
                continue;
            }
            
            
            Symbolinfo* symbol = symTable.lookUp(token);
            if (symbol && symbol->getType() == "FLOAT") {
                return "FLOAT";  
            }
        }
        
        return "INT";  
    }
    
    
    bool areTypesCompatible(const std::string& leftType, const std::string& rightType) {
        if (leftType == rightType) return true;
        if (leftType == "FLOAT" && rightType == "INT") return true;  
        return false;  
    }
    
    
    bool isArrayVariable(const std::string& varName) {
        Symbolinfo* symbol = symTable.lookUp(varName);
        if (symbol) {
            return symbol->getArrayType();
        }
        return false;
    }
    
    
    bool checkFunctionReturnTypeMismatch(const std::string& functionName, const std::string& newReturnType) {
        Symbolinfo* existingSymbol = symTable.lookUp(functionName);
        if (existingSymbol && existingSymbol->getType() == "FUNCTION") {
            return existingSymbol->getReturnType() != newReturnType;
        }
        return false;
    }
    
    
    bool checkFunctionParameterCountMismatch(const std::string& functionName, const std::vector<std::pair<std::string, std::string>>& newParameters) {
        Symbolinfo* existingSymbol = symTable.lookUp(functionName);
        if (existingSymbol && existingSymbol->getType() == "FUNCTION") {
            std::vector<std::pair<std::string, std::string>> existingParameters = existingSymbol->getParameters();
            return existingParameters.size() != newParameters.size();
        }
        return false;
    }
    
    
    bool checkFunctionParameterTypeMismatch(const std::string& functionName, const std::vector<std::pair<std::string, std::string>>& newParameters) {
        Symbolinfo* existingSymbol = symTable.lookUp(functionName);
        if (existingSymbol && existingSymbol->getType() == "FUNCTION") {
            std::vector<std::pair<std::string, std::string>> existingParameters = existingSymbol->getParameters();
            if (existingParameters.size() == newParameters.size()) {
                for (size_t i = 0; i < newParameters.size(); i++) {
                    if (existingParameters[i].second != newParameters[i].second) {
                        return true; 
                    }
                }
            }
        }
        return false;
    }
    
    
    std::string currentFunctionReturnType;
    std::string currentFunctionName;
    
    
    std::string checkArgumentTypeMismatch(const std::string& functionName, const std::vector<std::string>& argumentTypes) {
        Symbolinfo* functionSymbol = symTable.lookUp(functionName);
        if (functionSymbol && functionSymbol->getType() == "FUNCTION") {
            std::vector<std::pair<std::string, std::string>> expectedParams = functionSymbol->getParameters();
            
            if (expectedParams.size() != argumentTypes.size()) {
                return ""; 
            }
            
            for (size_t i = 0; i < argumentTypes.size(); i++) {
                std::string expectedType = expectedParams[i].second;
                std::string actualType = argumentTypes[i];
                
                
                if (expectedType != actualType) {
                    
                    if (!(expectedType == "FLOAT" && actualType == "INT")) {
                        
                        std::string ordinal;
                        int pos = i + 1;
                        int lastTwoDigits = pos % 100;
                        int lastDigit = pos % 10;
                        
                        if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
                            
                            ordinal = std::to_string(pos) + "th";
                        } else if (lastDigit == 1) {
                            ordinal = std::to_string(pos) + "st";
                        } else if (lastDigit == 2) {
                            ordinal = std::to_string(pos) + "nd";
                        } else if (lastDigit == 3) {
                            ordinal = std::to_string(pos) + "rd";
                        } else {
                            ordinal = std::to_string(pos) + "th";
                        }
                        return ordinal; 
                    }
                }
            }
        }
        return ""; 
    }
}

start :{IntitalizeCode();} program
	{
        std::ostringstream buffer;
        symTable.printAllScopeTables(buffer);
        std::string symbolTableOutput = buffer.str();
	    
        if (!symbolTableOutput.empty()) {
           
        } else {
        }
		
	}
	;

program returns [std::string formatted_text]
    : p=program u=unit 
	{
		$formatted_text = $p.formatted_text + "\n" + $u.formatted_text;
	}
	| u=unit
	{
		$formatted_text = $u.formatted_text;
	}
	;
	
unit returns [std::string formatted_text]
    : var_declaration
	{
		$formatted_text = $var_declaration.formatted_text;
	}
     | func_declaration
	{
		$formatted_text = $func_declaration.formatted_text;
	}
     | func_definition
	{
		$formatted_text = $func_definition.formatted_text;
	}
     ;
     
func_declaration returns [std::string formatted_text] 
    : type_specifier ID LPAREN pl=parameter_list RPAREN SEMICOLON
	{
		
		$formatted_text = $type_specifier.text + " " + $ID->getText() + "(" + $pl.formatted_text + ");";
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		
		std::vector<std::pair<std::string, std::string>> emptyParams;
		
		
		if (checkFunctionReturnTypeMismatch($ID->getText(), $type_specifier.type_name)) {
			syntaxErrorCount++;
		} 
		
		else if (checkFunctionParameterCountMismatch($ID->getText(), emptyParams)) {
			syntaxErrorCount++;
		}
		else {
			
			bool inserted = symTable.insertFunction($ID->getText(), $type_specifier.type_name, false, emptyParams);
			if (!inserted) {
				syntaxErrorCount++;
			}
		}
		
		$formatted_text = $type_specifier.text + " " + $ID->getText() + "();";
	}
	;
		 
func_definition returns [std::string formatted_text] 
    : type_specifier ID LPAREN pl=parameter_list RPAREN {
    	currentFunctionReturnType = $type_specifier.type_name;
    	currentFunctionName = $ID->getText();
    	hasReturnValue = false; 
		currentFunctionParams = $pl.params;
		currentFunctionParamCount = $pl.params.size();
		offset=2;
		localVarSpace=0;
		if($ID->getText()=="main")
		{
			WriteMachine("main PROC\n\t\tMOV AX, @DATA\n\t\tMOV DS, AX");
			WriteMachine("\t\tPUSH BP\n\t\tMOV BP, SP");
		}
		else{
			WriteMachine($ID->getText() + " PROC");
			WriteMachine("\t\tPUSH BP\n\t\tMOV BP, SP");
		}
    } compound_statement
	{
		$formatted_text = $type_specifier.text + " " + $ID->getText() + "(" + $pl.formatted_text + ")" + $compound_statement.formatted_text;
		
		if (!hasReturnValue) {
			if ($ID->getText() == "main") {
				WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
				WriteMachine("\t\tPOP BP");
				WriteMachine("\t\tMOV AX,4CH");
				WriteMachine("\t\tINT 21H");
			} else {
				if ($type_specifier.type_name == "VOID") {
					WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
					WriteMachine("\t\tPOP BP");
					if (currentFunctionParamCount > 0) {
						WriteMachine("\t\tRET " + std::to_string(2 * currentFunctionParamCount));
					} else {
						WriteMachine("\t\tRET");
					}
				} else {
					WriteMachine("\t\tMOV AX, 0");
					WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
					WriteMachine("\t\tPOP BP");
					if (currentFunctionParamCount > 0) {
						WriteMachine("\t\tRET " + std::to_string(2 * currentFunctionParamCount));
					} else {
						WriteMachine("\t\tRET");
					}
				}
			}
		}
		
		currentFunctionParams.clear();
		currentFunctionReturnType = "";
		currentFunctionName = "";
		hasReturnValue = false;
		
		
		WriteMachine($ID->getText() + " ENDP");
	}
	| type_specifier ID LPAREN RPAREN {
		currentFunctionReturnType = $type_specifier.type_name;
		currentFunctionName = $ID->getText();
		hasReturnValue = false; 
		offset=2;
		localVarSpace=0;
		currentFunctionParamCount = 0;

		std::vector<std::pair<std::string, std::string>> emptyParams;
		currentFunctionParams.clear();
		if ($ID->getText()=="main")
		{
			WriteMachine("main PROC\n\t\tMOV AX, @DATA\n\t\tMOV DS, AX");
			WriteMachine("\t\tPUSH BP\n\t\tMOV BP, SP");
		}
		else{
			WriteMachine($ID->getText() + " PROC");
			WriteMachine("\t\tPUSH BP\n\t\tMOV BP, SP");
		}
	} compound_statement
	{
		$formatted_text = $type_specifier.text + " " + $ID->getText() + "()" + $compound_statement.formatted_text;
		
		if (!hasReturnValue) {
			if ($ID->getText() == "main") {
				WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
				WriteMachine("\t\tPOP BP");
				WriteMachine("\t\tMOV AX,4CH");
				WriteMachine("\t\tINT 21H");
			} else {
				if ($type_specifier.type_name == "VOID") {
					WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
					WriteMachine("\t\tPOP BP");
					if (currentFunctionParamCount > 0) {
						WriteMachine("\t\tRET " + std::to_string(2 * currentFunctionParamCount));
					} else {
						WriteMachine("\t\tRET");
					}
				} else {
					WriteMachine("\t\tMOV AX, 0");
					WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
					WriteMachine("\t\tPOP BP");
					if (currentFunctionParamCount > 0) {
						WriteMachine("\t\tRET " + std::to_string(2 * currentFunctionParamCount));
					} else {
						WriteMachine("\t\tRET");
					}
				}
			}
		}
		
		currentFunctionReturnType = "";
		currentFunctionName = "";
		hasReturnValue = false;
		
		WriteMachine($ID->getText() + " ENDP");
	}
 	;				


parameter_list returns [std::string formatted_text, std::vector<std::pair<std::string, std::string>> params] : pl=parameter_list COMMA type_specifier ID
	{
		$formatted_text = $pl.formatted_text + ", " + $type_specifier.text + " " + $ID->getText();
		$params = $pl.params;
		
		
		for (const auto& param : $params) {
			if (param.first == $ID->getText()) {
				syntaxErrorCount++;
				break;
			}
		}
		
		$params.push_back(std::make_pair($ID->getText(), $type_specifier.type_name));
	}
	| pl=parameter_list COMMA type_specifier
	{
		$formatted_text = $pl.formatted_text + ", " + $type_specifier.text;
		$params = $pl.params;
	}
 	| type_specifier ID
	{
		$formatted_text = $type_specifier.text + " " + $ID->getText();
		$params.push_back(std::make_pair($ID->getText(), $type_specifier.type_name));
	}
	| type_specifier
	{
		$formatted_text = $type_specifier.text;
		
	}
 	;

 		
compound_statement returns [std::string formatted_text] : LCURL 
	{
		
		symTable.enterScope(false);
		
		
		int paramOffset = 4 + (currentFunctionParams.size() - 1) * 2;
		for (const auto& param : currentFunctionParams) {
			symTable.insertParameter(param.first, param.second, false, false);
			Symbolinfo* paramSymbol = symTable.lookUp(param.first);
			if (paramSymbol) {
				paramSymbol->setOffset(paramOffset);
				paramOffset -= 2;
			}
		}
	}
	statements RCURL
	{
		$formatted_text = "{\n" + $statements.formatted_text + "\n}";
		
		std::ostringstream scopeBuffer;
		symTable.printAllScopeTables(scopeBuffer);


		if (currentFunctionReturnType == "VOID"&& hasReturnValue) {
			syntaxErrorCount++;
			hasReturnValue = false; 
		}
		
		
		
		symTable.exitScope(false);
		
		
	}
 	    | LCURL 
	{
		
		symTable.enterScope(false);
		
		
		for (const auto& param : currentFunctionParams) {
			symTable.insert(param.first, param.second, false, false);
		}
	}
	RCURL
	{
		$formatted_text = "{}";
		
		std::ostringstream scopeBuffer;
		symTable.printAllScopeTables(scopeBuffer);
		
		
		symTable.exitScope(false);
		
	
	}
 	    ;
 		    
var_declaration returns [std::string formatted_text]
    : t=type_specifier {
    	currentVarType = $t.type_name;
    } dl=declaration_list sm=SEMICOLON {

		std::vector<std::string>vars = $dl.var;
		std::string code="";
		for (const auto &varname:vars)
		{
			Symbolinfo* syminfo = symTable.lookUp(varname);
			
			if (!syminfo) {
				continue;
			}
			
			if (syminfo && syminfo->getArrayType())
			{
				if (symTable.getSymbolTableNum() == 1){
					syminfo->setIsGlobal(true);
					std::string arrayType = syminfo->getType();
					string arrsize=std::to_string (syminfo->getArraySize());

					if (arrayType == "INT_ARRAY") {
						code="\t\t"+varname+" DW "+ arrsize+" DUP (0000H)";
					} else if (arrayType == "FLOAT_ARRAY") {
						code="\t\t"+varname+" DD "+arrsize+" DUP (0000H)";
					}
					WriteMachine2(code);
				}
				else{
					syminfo->setOffset(offset);
					offset+=2*syminfo->getArraySize();
					localVarSpace+=2*syminfo->getArraySize();
					syminfo->setIsGlobal(false);
					WriteMachine("\t\tSUB SP, " + std::to_string(2 * syminfo->getArraySize()));
				}
			}
			else{
				if (symTable.getSymbolTableNum() == 1)
				{	
					syminfo->setIsGlobal(true);
					code="\t\t"+varname+" DW 1 DUP (0000H)";
					WriteMachine2(code);
				}
				else{
					syminfo->setOffset(offset);
					offset+=2;
					localVarSpace+=2;
					syminfo->setIsGlobal(false);
					code="\t\tSUB SP, 2";
					WriteMachine(code);
				}
			}
		}
    } 

    | t=type_specifier {
    	currentVarType = $t.type_name;
    } de=declaration_list_err sm=SEMICOLON {

        
      }
    ;

declaration_list_err returns [std::string error_name, std::string data]: {
        $error_name = "Error in declaration list";
        $data = "";
    };

 		 
type_specifier returns [std::string name_line,std::string type_name]	
        : INT {
            $name_line = "type: INT at line" + std::to_string($INT->getLine());
			$type_name = "INT";
        }
 		| FLOAT {
            $name_line = "type: FLOAT at line" + std::to_string($FLOAT->getLine());
			$type_name = "FLOAT";
        }
 		| VOID {
            $name_line = "type: VOID at line" + std::to_string($VOID->getLine());
			$type_name = "VOID";
        }
 		;
 		
declaration_list returns [std::vector<std::string>var] :dl= declaration_list COMMA id=ID
		{
			$var= $dl.var;
			$var.push_back($id->getText());
			
			bool inserted = symTable.insert($id->getText(), currentVarType, false, false);
			if (!inserted) {
				syntaxErrorCount++;
			}

		}
 		  |dl= declaration_list COMMA id=ID LTHIRD CONST_INT RTHIRD{
			$var= $dl.var;
			$var.push_back($id->getText() );
			
			std::string arrayType = currentVarType + "_ARRAY";
			bool inserted = symTable.insert($id->getText(), arrayType, false, true);
			if (inserted) {
				symTable.lookUp($id->getText())->setArraySize(std::stoi($CONST_INT->getText()));
				symTable.lookUp($id->getText())->setArrayType(true);
			}
			if (!inserted) {
				syntaxErrorCount++;
			}
		  }
 		  |id=ID{
			$var.push_back($id->getText());
			
			bool inserted = symTable.insert($id->getText(), currentVarType, false, false);
			if (!inserted) {
				syntaxErrorCount++;
			}
		  }
 		  |id=ID LTHIRD CONST_INT RTHIRD{
			$var.push_back($id->getText() );
			
			std::string arrayType = currentVarType + "_ARRAY";
		
			bool inserted = symTable.insert($id->getText(), arrayType, false, true);
			if (inserted) {
				symTable.lookUp($id->getText())->setArraySize(std::stoi($CONST_INT->getText()));
				symTable.lookUp($id->getText())->setArrayType(true);
			}
			if (!inserted) {
				syntaxErrorCount++;
			}
		  }
 		  ;
 		  
statements returns [std::string formatted_text] : statement
	{
		$formatted_text = $statement.formatted_text;
	}
	   | ss=statements statement
	{
		$formatted_text = $ss.formatted_text + "\n" + $statement.formatted_text;
	}
	   ;
	   
statement returns [std::string formatted_text] : var_declaration
	{
		$formatted_text = $var_declaration.formatted_text;
	}
	  | expression_statement
	{
		$formatted_text = $expression_statement.text;
	}
	  | compound_statement
	{
		$formatted_text = $compound_statement.formatted_text;
	}
	  | FOR
	  {
		loopcount++;
		looplabels.push_back(std::to_string(loopcount));
	  } LPAREN es1=expression_statement{
		WriteMachine("Loop"+looplabels.back()+":");
		
	  } es2=expression_statement
	  {
		if (!$es2.text.empty() && $es2.text != ";") {
			WriteMachine("\t\tPOP AX");
			WriteMachine("\t\tCMP AX, 0");
			WriteMachine("\t\tJE Loop_end"+looplabels.back());
		}
		WriteMachine("\t\tJMP Loop_body"+looplabels.back());
		WriteMachine("Loop_mid"+looplabels.back()+":");
	  } expression RPAREN {
		WriteMachine("\t\tPOP AX");
		WriteMachine("\t\tJMP Loop"+looplabels.back());
		WriteMachine("Loop_body"+looplabels.back()+":");
		incrementLabels.pop_back(); 
	  } statement
	{
		WriteMachine("\t\tJMP Loop_mid"+looplabels.back());
		WriteMachine("Loop_end"+looplabels.back()+":");
		looplabels.pop_back();
		
		$formatted_text = $FOR->getText() + " (" + $es1.text + " " + $es2.text + " " + $expression.text + ") " + $statement.formatted_text;
	}
	  | IF LPAREN expression 
	  {
		WriteMachine("\t\tPOP AX");
		WriteMachine("\t\tCMP AX, 0");
		string skipLabel = "L" + std::to_string(level++);
		exitlabels.push_back(skipLabel);
		WriteMachine("\t\tJE " + skipLabel);
	  } RPAREN s1=statement
	{
		WriteMachine(exitlabels.back() + ":");
		exitlabels.pop_back();
		$formatted_text = $IF->getText() + " (" + $expression.text + ") " + $s1.formatted_text;
	}
	  | IF LPAREN expression
	  {
		string label = "L" + std::to_string(level++);
		elselabels.push_back(label);
		WriteMachine("\t\tPOP AX");
		WriteMachine("\t\tCMP AX, 0");
		WriteMachine("\t\tJE " + label);

	  } RPAREN s1=statement
	  {
		string label2 = "L" + std::to_string(level++);
		exitlabels.push_back(label2);
		WriteMachine("\t\tJMP " + label2);
		WriteMachine(elselabels.back() + ":");
		elselabels.pop_back();
	  } ELSE s2=statement
	{	
		    WriteMachine(exitlabels.back() + ":"); 
		exitlabels.pop_back();
		$formatted_text = $IF->getText() + " (" + $expression.text + ") " + $s1.formatted_text + " " + $ELSE->getText() + " " + $s2.formatted_text;
	}
	  | WHILE
	  {
		loopcount++;
		looplabels.push_back(std::to_string(loopcount));
		WriteMachine("While_start" + looplabels.back() + ":");
	  } LPAREN expression RPAREN{
		WriteMachine("\t\tPOP AX");
		WriteMachine("\t\tCMP AX, 0");
		WriteMachine("\t\tJE While_end" + looplabels.back());
	  } statement
	{
		WriteMachine("\t\tJMP While_start" + looplabels.back());
		WriteMachine("While_end" + looplabels.back() + ":");
		looplabels.pop_back();
		$formatted_text = $WHILE->getText() + " (" + $expression.text + ") " + $statement.formatted_text;
	}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		std::string varType = $ID->getText();
		Symbolinfo* entry = symTable.lookUp(varType);

		if(entry && entry->getIsGlobal())
		{
			WriteMachine("\t\tMOV AX, "+$ID->getText());
			WriteMachine("\t\tCALL print_output");
			WriteMachine("\t\tCALL new_line");
		}
		else{
			Symbolinfo* syminfo = symTable.lookUp(varType);
			int offset = syminfo->getOffset();
			if (syminfo->getIsParameter()) {
				WriteMachine("\t\tMOV AX, [BP+"+std::to_string(offset)+"]");
			} else {
				WriteMachine("\t\tMOV AX, [BP-"+std::to_string(offset)+"]");
			}
			WriteMachine("\t\tCALL print_output");
			WriteMachine("\t\tCALL new_line");
		}

		$formatted_text = $PRINTLN->getText() + "(" + $ID->getText() + ");";
	}
	| PRINT LPAREN ID RPAREN SEMICOLON
	{
		std::string varType = $ID->getText();
		Symbolinfo* entry = symTable.lookUp(varType);

		if(entry && entry->getIsGlobal())
		{
			WriteMachine("\t\tMOV AX, "+$ID->getText());
			WriteMachine("\t\tCALL print_output");
			WriteMachine("\t\tCALL new_line");
		}
		else{
			Symbolinfo* syminfo = symTable.lookUp(varType);
			int offset = syminfo->getOffset();
			if (syminfo->getIsParameter()) {
				WriteMachine("\t\tMOV AX, [BP+"+std::to_string(offset)+"]");
			} else {
				WriteMachine("\t\tMOV AX, [BP-"+std::to_string(offset)+"]");
			}
			WriteMachine("\t\tCALL print_output");
			WriteMachine("\t\tCALL new_line");
		}

	}
	| RETURN expression SEMICOLON
	{	
		WriteMachine("\t\tPOP AX");           
		WriteMachine("\t\tADD SP,"+std::to_string(localVarSpace));
		WriteMachine("\t\tPOP BP");
		
		if (currentFunctionName == "main") {
			WriteMachine("\t\tMOV AX,4CH");
			WriteMachine("\t\tINT 21H");
		} else {
			if (currentFunctionParamCount > 0) {
				WriteMachine("\t\tRET " + std::to_string(2 * currentFunctionParamCount));
			} else {
				WriteMachine("\t\tRET");
			}
		}

		hasReturnValue = true;
		$formatted_text = $RETURN->getText() + " " + $expression.text + ";";
	}
	  ;
	  
expression_statement 	: SEMICOLON
	{
	}			
			| expression SEMICOLON 
	{
		
		bool hasAssignment = ($expression.formatted_text.find("=") != std::string::npos);
		bool hasIncDec = ($expression.formatted_text.find("++") != std::string::npos || 
		                  $expression.formatted_text.find("--") != std::string::npos);
		
		if (!hasAssignment && hasIncDec) {
			int incCount = 0;
			size_t pos = 0;
			while ((pos = $expression.formatted_text.find("++", pos)) != std::string::npos) {
				incCount++;
				pos += 2;
			}
			pos = 0;
			while ((pos = $expression.formatted_text.find("--", pos)) != std::string::npos) {
				incCount++;
				pos += 2;
			}
			
			for (int i = 0; i < incCount; i++) {
				WriteMachine("\t\tPOP AX");
			}
		}
		
		incrementLabels.clear();
	}
			;
	  
variable : ID 
	{
		
		
		if (symTable.lookUp($ID->getText()) && symTable.lookUp($ID->getText())->getArrayType()) {
			syntaxErrorCount++;
		}
		if (!symTable.lookUp($ID->getText())) {
			syntaxErrorCount++;
		}
		
	}		
	 | ID LTHIRD expression RTHIRD 
	{	
		
		if (!symTable.lookUp($ID->getText())) {
			syntaxErrorCount++;
		}
		
		Symbolinfo* entry = symTable.lookUp($ID->getText());
		if (entry && !entry->getArrayType()) {
			syntaxErrorCount++;
		}
		

		
		if ($expression.text.find('.') != std::string::npos) {
			syntaxErrorCount++;
		}
		
	}
	 ;
	 
 expression returns [std::string formatted_text] : logic_expression
	{
		$formatted_text = $logic_expression.formatted_text;
	}	
	   | variable ASSIGNOP logic_expression 
	{
		std::string varName;
		std::string varText = $variable.text;
		
		size_t bracketPos = varText.find('[');
		if (bracketPos != std::string::npos) {
			varName = varText.substr(0, bracketPos);
			Symbolinfo* syminfo = symTable.lookUp(varName);
			
			if (syminfo && syminfo->getArrayType()) {
				WriteMachine("\t\tPOP AX");
				WriteMachine("\t\tPOP BX");
				
				if (syminfo->getIsGlobal()) {
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tPOP AX");
					WriteMachine("\t\tMOV " + varName + "[BX], AX");
				} else {
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					int totalLocalSpace = syminfo->getOffset() + (syminfo->getArraySize() * 2);
					WriteMachine("\t\tMOV AX, " + std::to_string(totalLocalSpace));
					WriteMachine("\t\tSUB AX, BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tPOP AX");
					WriteMachine("\t\tMOV SI, BX");
					WriteMachine("\t\tNEG SI");
					WriteMachine("\t\tMOV [BP+SI], AX");
				}
			}
		} else {
			varName = varText;
			Symbolinfo* syminfo = symTable.lookUp(varName);
			
			if (syminfo->getIsGlobal()) {
				WriteMachine("\t\tPOP AX");
				WriteMachine("\t\tMOV " + varName + ", AX");
			} else {
				int off = syminfo->getOffset();
				if (syminfo->getIsParameter()) {
					WriteMachine("\t\tPOP AX");
					WriteMachine("\t\tMOV [BP+" + std::to_string(off) + "], AX");
				} else {
					WriteMachine("\t\tPOP AX");
					WriteMachine("\t\tMOV [BP-" + std::to_string(off) + "], AX");
				}
			}
		}
		
		$formatted_text = $variable.text + " " + $ASSIGNOP->getText() + " " + $logic_expression.formatted_text;
	}	
	   ;
			
logic_expression returns [std::string formatted_text,std::string funcName] : rel_expression 
	{
		$formatted_text = $rel_expression.formatted_text;
		$funcName = $rel_expression.funcName;
	}	
		 | re1=rel_expression LOGICOP re2=rel_expression 
	{
		
		if ($re1.funcName.empty()) {
			$funcName = $re2.funcName;
		} else if ($re2.funcName.empty()) {
			$funcName = $re1.funcName;
		} 
	std::string op = $LOGICOP->getText();
    std::string shortCircuitLabel = "L" + std::to_string(level++);
    std::string endLabel = "L" + std::to_string(level++);
    
    if (op == "&&") {
    
        WriteMachine("\t\tPOP AX");          
        WriteMachine("\t\tCMP AX, 0");        
        WriteMachine("\t\tJE " + shortCircuitLabel); 
       
        WriteMachine("\t\tPOP BX");          
        WriteMachine("\t\tAND AX, BX");       
        WriteMachine("\t\tJMP " + endLabel);   
        WriteMachine(shortCircuitLabel + ":");
        WriteMachine("\t\tMOV AX, 0");       
        WriteMachine(endLabel + ":");
        WriteMachine("\t\tPUSH AX");
        
    } else if (op == "||") {
      
        WriteMachine("\t\tPOP AX");         
        WriteMachine("\t\tCMP AX, 0");      
        WriteMachine("\t\tJNE " + shortCircuitLabel); 
        

        WriteMachine("\t\tPOP BX");           
        WriteMachine("\t\tOR AX, BX");       
        WriteMachine("\t\tJMP " + endLabel);
        
        WriteMachine(shortCircuitLabel + ":");
        WriteMachine("\t\tMOV AX, 1");    
        
        WriteMachine(endLabel + ":");
        WriteMachine("\t\tPUSH AX");
    }

		$formatted_text = $re1.formatted_text + " " + $LOGICOP->getText() + " " + $re2.formatted_text;
	}	
		 ;
			
rel_expression returns [std::string formatted_text,std::string funcName]	: simple_expression 
	{
		$formatted_text = $simple_expression.formatted_text;
		$funcName = $simple_expression.funcName;
	}
		| se1=simple_expression RELOP se2=simple_expression	
	{
		 if ($se1.funcName.empty()) {
			$funcName = $se2.funcName;
		} else if ($se2.funcName.empty()) {
			$funcName = $se1.funcName;
		}
		std::string op = $RELOP->getText();
		WriteMachine("\t\tPOP BX");    
        WriteMachine("\t\tPOP AX");         
        WriteMachine("\t\tCMP AX, BX");
		string truelabel="L"+std::to_string(level++);
		string falselabel="L"+std::to_string(level++);
		if (op == "==") {
			WriteMachine("\t\tJE " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		} else if (op == "!=") {
			WriteMachine("\t\tJNE " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		} else if (op == "<") {
			WriteMachine("\t\tJL " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		} else if (op == "<=") {
			WriteMachine("\t\tJLE " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		} else if (op == ">") {
			WriteMachine("\t\tJG " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		} else if (op == ">=") {
			WriteMachine("\t\tJGE " + truelabel);
			WriteMachine("\t\tJMP " + falselabel);
		}
		std::string nextlabel = "L" + std::to_string(level++);
		WriteMachine(truelabel+":\n\t\tPUSH 1\n\t\tJMP " + nextlabel);
		WriteMachine(falselabel+":\n\t\tPUSH 0");
		WriteMachine(nextlabel+":");



		$formatted_text = $se1.formatted_text + " " + $RELOP->getText() + " " + $se2.formatted_text;
	}
		;
				
simple_expression returns [std::string formatted_text,std::string funcName] : term 
	{
		$formatted_text = $term.formatted_text;
		$funcName = $term.funcName;
	}
		  | se=simple_expression ADDOP term 
	{	$funcName = $term.funcName;
		$formatted_text = $se.formatted_text + $ADDOP->getText() + $term.formatted_text;
		WriteMachine("\t\tPOP AX\n\t\tMOV DX, AX");
		if ($ADDOP->getText() == "+") {
			WriteMachine("\t\tPOP AX\n\t\tADD AX, DX\n\t\tPUSH AX");
		} else if ($ADDOP->getText() == "-") {
			WriteMachine("\t\tPOP AX\n\t\tSUB AX, DX\n\t\tPUSH AX");
		}
	}
		  ;
					
term returns [std::string formatted_text,std::string funcName] :	unary_expression
	{
		$funcName = $unary_expression.funcName;
		$formatted_text = $unary_expression.formatted_text;
	}
     |  t=term MULOP unary_expression
	{	
		$funcName = $unary_expression.funcName;
		
		if ($MULOP->getText() == "%") {
			std::string leftType = inferExpressionType($t.formatted_text);
			std::string rightType = inferExpressionType($unary_expression.formatted_text);
			WriteMachine("\t\tPOP BX\n\t\tXOR DX,DX\n\t\tPOP AX\n\t\tDIV BX\n\t\tPUSH DX");
			if (leftType == "FLOAT" || rightType == "FLOAT") {
				syntaxErrorCount++;
			}
		}
		else{
			WriteMachine("\t\tPOP AX\n\t\tPOP BX\n\t\tIMUL BX\n\t\tPUSH AX");
		}
		std::string functionName = $unary_expression.funcName;
		if (!functionName.empty()) {
			Symbolinfo* funcSymbol = symTable.lookUp(functionName);
			if (funcSymbol && funcSymbol->getReturnType() == "VOID") {
				syntaxErrorCount++;
				istermerror=true;
			}

		}
		
		
		$formatted_text = $t.formatted_text + $MULOP->getText() + $unary_expression.formatted_text;
	}
     ;

unary_expression returns [std::string formatted_text,std::string funcName] : ADDOP ue=unary_expression  
	{
		if ($ADDOP->getText() == "+") {
			$funcName = $ue.funcName;
		} else if ($ADDOP->getText() == "-") {
			$funcName = $ue.funcName;
			WriteMachine("\t\tPOP AX\n\t\tNEG AX\n\t\tPUSH AX");
		} 
		$formatted_text = $ADDOP->getText() + $ue.formatted_text;
	}
		 | NOT ue=unary_expression 
	{
		$formatted_text = $NOT->getText() + $ue.formatted_text;
	}
		 | factor 
	{
		$funcName = $factor.funcname;
		$formatted_text = $factor.formatted_text;
		
	}
		 ;
	
factor returns [std::string formatted_text,std::string funcname] : variable 
	{
		$formatted_text = $variable.text;
		std::string varname = $variable.text;
		size_t bracketPos = $variable.text.find('[');
		
		if (bracketPos != std::string::npos) {
			$funcname = $variable.text.substr(0, bracketPos);
			Symbolinfo* syminfo = symTable.lookUp($funcname);
			
			if (syminfo && syminfo->getArrayType()) {
				WriteMachine("\t\tPOP BX");
				
				if (syminfo->getIsGlobal()) {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV AX, " + $funcname + "[BX]");
					WriteMachine("\t\tPUSH AX");
				} else {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					int off = syminfo->getOffset();
					int totalLocalSpace = off + (syminfo->getArraySize() * 2);
					WriteMachine("\t\tMOV AX, " + std::to_string(totalLocalSpace));
					WriteMachine("\t\tSUB AX, BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV SI, BX");
					WriteMachine("\t\tNEG SI");
					WriteMachine("\t\tMOV AX, [BP+SI]");
					WriteMachine("\t\tPUSH AX");
				}
			}
		} else {
			$funcname = $variable.text;
			Symbolinfo* syminfo = symTable.lookUp($funcname);
			
			if (syminfo && syminfo->getIsGlobal()) {
				WriteMachine("\t\tMOV AX, " + $funcname);
				WriteMachine("\t\tPUSH AX");
			} else {
				int off = syminfo->getOffset();
				if (syminfo->getIsParameter()) {
					WriteMachine("\t\tMOV AX, [BP+" + std::to_string(off) + "]");
				} else {
					WriteMachine("\t\tMOV AX, [BP-" + std::to_string(off) + "]");
				}
				WriteMachine("\t\tPUSH AX");
			}
		}
	}
	| ID LPAREN argument_list RPAREN
	{
		
		$funcname = $ID->getText();
		currentFunc = $ID->getText(); 
		$formatted_text = $ID->getText() + "(" + $argument_list.formatted_text + ")";
		WriteMachine("\t\tCALL " + $ID->getText());
        WriteMachine("\t\tPUSH AX");
		argcount.clear();
		
		
	}

	| LPAREN expression RPAREN
	{
		$formatted_text = "(" + $expression.formatted_text + ")";
	}
	| CONST_INT 
	{
		$formatted_text = $CONST_INT->getText();
		WriteMachine("\t\tMOV AX, "+$CONST_INT->getText());
		WriteMachine("\t\tPUSH AX");
	}
	| CONST_FLOAT
	{
		$formatted_text = $CONST_FLOAT->getText();
	}
	| variable INCOP 
	{
		incrementLabels.push_back(2);
		std::string varText = $variable.text;
		size_t bracketPos = varText.find('[');
		
		if (bracketPos != std::string::npos) {
			std::string varName = varText.substr(0, bracketPos);
			Symbolinfo* syminfo = symTable.lookUp(varName);
			
			if (syminfo && syminfo->getArrayType()) {
				WriteMachine("\t\tPOP BX");
				
				if (syminfo->getIsGlobal()) {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV AX, " + varName + "[BX]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tINC AX");
					WriteMachine("\t\tMOV " + varName + "[BX], AX");
				} else {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					int off = syminfo->getOffset();
					int totalLocalSpace = off + (syminfo->getArraySize() * 2);
					WriteMachine("\t\tMOV AX, " + std::to_string(totalLocalSpace));
					WriteMachine("\t\tSUB AX, BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV SI, BX");
					WriteMachine("\t\tNEG SI");
					WriteMachine("\t\tMOV AX, [BP+SI]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tINC AX");
					WriteMachine("\t\tMOV [BP+SI], AX");
				}
			}
		} else {
			Symbolinfo* syminfo = symTable.lookUp($variable.text);
			if (syminfo && syminfo->getIsGlobal()) {
				WriteMachine("\t\tMOV AX, " + $variable.text);
				WriteMachine("\t\tPUSH AX");
				WriteMachine("\t\tINC AX");
				WriteMachine("\t\tMOV " + $variable.text + ", AX");
			} else {
				int off = syminfo->getOffset();
				if (syminfo->getIsParameter()) {
					WriteMachine("\t\tMOV AX, [BP+" + std::to_string(off) + "]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tINC AX");
					WriteMachine("\t\tMOV [BP+" + std::to_string(off) + "], AX");
				} else {
					WriteMachine("\t\tMOV AX, [BP-" + std::to_string(off) + "]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tINC AX");
					WriteMachine("\t\tMOV [BP-" + std::to_string(off) + "], AX");
				}
			}
		}
		$formatted_text = $variable.text + $INCOP->getText();
	}
	| variable DECOP
	{	
		incrementLabels.push_back(2);
		std::string varText = $variable.text;
		size_t bracketPos = varText.find('[');
		
		if (bracketPos != std::string::npos) {
			std::string varName = varText.substr(0, bracketPos);
			Symbolinfo* syminfo = symTable.lookUp(varName);
			
			if (syminfo && syminfo->getArrayType()) {
				WriteMachine("\t\tPOP BX");
				
				if (syminfo->getIsGlobal()) {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV AX, " + varName + "[BX]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tDEC AX");
					WriteMachine("\t\tMOV " + varName + "[BX], AX");
				} else {
					WriteMachine("\t\tMOV AX, 2");
					WriteMachine("\t\tMUL BX");
					WriteMachine("\t\tMOV BX, AX");
					int off = syminfo->getOffset();
					int totalLocalSpace = off + (syminfo->getArraySize() * 2);
					WriteMachine("\t\tMOV AX, " + std::to_string(totalLocalSpace));
					WriteMachine("\t\tSUB AX, BX");
					WriteMachine("\t\tMOV BX, AX");
					WriteMachine("\t\tMOV SI, BX");
					WriteMachine("\t\tNEG SI");
					WriteMachine("\t\tMOV AX, [BP+SI]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tDEC AX");
					WriteMachine("\t\tMOV [BP+SI], AX");
				}
			}
		} else {
			Symbolinfo* syminfo = symTable.lookUp($variable.text);
			if (syminfo && syminfo->getIsGlobal()) {
				WriteMachine("\t\tMOV AX, " + $variable.text);
				WriteMachine("\t\tPUSH AX");
				WriteMachine("\t\tDEC AX");
				WriteMachine("\t\tMOV " + $variable.text + ", AX");
			} else {
				int off = syminfo->getOffset();
				if (syminfo->getIsParameter()) {
					WriteMachine("\t\tMOV AX, [BP+" + std::to_string(off) + "]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tDEC AX");
					WriteMachine("\t\tMOV [BP+" + std::to_string(off) + "], AX");
				} else {
					WriteMachine("\t\tMOV AX, [BP-" + std::to_string(off) + "]");
					WriteMachine("\t\tPUSH AX");
					WriteMachine("\t\tDEC AX");
					WriteMachine("\t\tMOV [BP-" + std::to_string(off) + "], AX");
				}
			}
		}
		$formatted_text = $variable.text + $DECOP->getText();
	}
	;
	
argument_list returns [std::string formatted_text, std::vector<std::string> argTypes] : arguments
	{
		$formatted_text = $arguments.formatted_text;
		$argTypes = $arguments.argTypes;
	}
			  |
			  {
			  	$formatted_text = "";
			  	
			  }
			  ;
	
arguments returns [std::string formatted_text, std::vector<std::string> argTypes] : args=arguments COMMA logic_expression
	{
		argcount.push_back(2);
		$formatted_text = $args.formatted_text + ", " + $logic_expression.text;
		$argTypes = $args.argTypes;
		$argTypes.push_back(inferExpressionType($logic_expression.text));
	}
	      | logic_expression
	{
		argcount.push_back(2);
		$formatted_text = $logic_expression.text;
		$argTypes.push_back(inferExpressionType($logic_expression.text));
	}
	      ;