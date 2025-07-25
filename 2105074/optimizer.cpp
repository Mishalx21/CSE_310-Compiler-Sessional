#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <cctype>

using namespace std;

class CodeOptimizer {
private:
    vector<string> lines;
    
    string trim(const string& str) {
        size_t start = str.find_first_not_of(" \t\r\n");
        if (start == string::npos) return "";
        size_t end = str.find_last_not_of(" \t\r\n");
        return str.substr(start, end - start + 1);
    }
    
    void optimizeRedundantMOV() {
        for (size_t i = 0; i < lines.size() - 1; i++) {
            if (lines[i].empty()) continue;
            
            string line1 = trim(lines[i]);
            string line2 = trim(lines[i + 1]);
            
            if (line1.find("MOV") == 0 && line2.find("MOV") == 0) {
                size_t comma1 = line1.find(',');
                size_t comma2 = line2.find(',');
                
                if (comma1 != string::npos && comma2 != string::npos) {
                    string reg1 = trim(line1.substr(4, comma1 - 4));
                    string var1 = trim(line1.substr(comma1 + 1));
                    string reg2 = trim(line2.substr(4, comma2 - 4));
                    string var2 = trim(line2.substr(comma2 + 1));
                    
                    if (reg1 == var2 && var1 == reg2) {
                        lines[i + 1] = "";
                    }
                }
            }
        }
    }
    
    void optimizeRedundantPushPop() {
        for (size_t i = 0; i < lines.size() - 1; i++) {
            if (lines[i].empty()) continue;
            
            string line1 = trim(lines[i]);
            string line2 = trim(lines[i + 1]);
            
            if (line1.find("PUSH") == 0 && line2.find("POP") == 0) {
                string pushReg = trim(line1.substr(5));
                string popReg = trim(line2.substr(4));
                
                if (pushReg == popReg) {
                    lines[i] = "";
                    lines[i + 1] = "";
                }
            }
        }
    }
    
    void optimizeRedundantOperations() {
        for (size_t i = 0; i < lines.size(); i++) {
            if (lines[i].empty()) continue;
            
            string line = trim(lines[i]);
            
            if (line.find("ADD") == 0) {
                size_t comma = line.find(',');
                if (comma != string::npos) {
                    string operand = trim(line.substr(comma + 1));
                    if (operand == "0") {
                        lines[i] = "";
                    }
                }
            }
            
            if (line.find("SUB") == 0) {
                size_t comma = line.find(',');
                if (comma != string::npos) {
                    string operand = trim(line.substr(comma + 1));
                    if (operand == "0") {
                        lines[i] = "";
                    }
                }
            }
            
            if (line.find("MUL") == 0 || line.find("IMUL") == 0) {
                size_t comma = line.find(',');
                if (comma != string::npos) {
                    string operand = trim(line.substr(comma + 1));
                    if (operand == "1") {
                        lines[i] = "";
                    }
                }
            }
        }
    }
    
    void optimizeRedundantLabels() {
        map<string, string> labelMapping;
        
        for (size_t i = 0; i < lines.size(); i++) {
            if (lines[i].empty()) continue;
            
            string line = trim(lines[i]);
            if (line.back() == ':') {
                string currentLabel = line.substr(0, line.length() - 1);
                
                vector<string> consecutiveLabels;
                consecutiveLabels.push_back(currentLabel);
                
                size_t j = i + 1;
                while (j < lines.size()) {
                    if (lines[j].empty()) {
                        j++;
                        continue;
                    }
                    
                    string nextLine = trim(lines[j]);
                    if (nextLine.back() == ':') {
                        string nextLabel = nextLine.substr(0, nextLine.length() - 1);
                        consecutiveLabels.push_back(nextLabel);
                        j++;
                    } else {
                        break;
                    }
                }
                
                if (consecutiveLabels.size() > 1) {
                    string masterLabel = consecutiveLabels[0];
                    for (size_t k = 1; k < consecutiveLabels.size(); k++) {
                        labelMapping[consecutiveLabels[k]] = masterLabel;
                        for (size_t l = i + 1; l < j; l++) {
                            if (!lines[l].empty()) {
                                string labelLine = trim(lines[l]);
                                if (labelLine == consecutiveLabels[k] + ":") {
                                    lines[l] = "";
                                }
                            }
                        }
                    }
                }
                
                i = j - 1;
            }
        }
        
        for (size_t i = 0; i < lines.size(); i++) {
            if (lines[i].empty()) continue;
            
            for (const auto& mapping : labelMapping) {
                size_t pos = lines[i].find(mapping.first);
                if (pos != string::npos) {
                    if (pos == 0 || !isalnum(lines[i][pos-1])) {
                        if (pos + mapping.first.length() == lines[i].length() || 
                            !isalnum(lines[i][pos + mapping.first.length()])) {
                            lines[i].replace(pos, mapping.first.length(), mapping.second);
                        }
                    }
                }
            }
        }
    }
    
public:
    bool loadFile(const string& filename) {
        ifstream inputFile(filename);
        if (!inputFile.is_open()) {
            return false;
        }
        
        lines.clear();
        string line;
        while (getline(inputFile, line)) {
            lines.push_back(line);
        }
        inputFile.close();
        return true;
    }
    
    void optimize() {
        optimizeRedundantMOV();
        optimizeRedundantPushPop();
        optimizeRedundantOperations();
        optimizeRedundantLabels();
    }
    
    bool saveFile(const string& filename) {
        ofstream outputFile(filename);
        if (!outputFile.is_open()) {
            return false;
        }
        
        for (const auto& line : lines) {
            if (!line.empty()) {
                outputFile << line << endl;
            }
        }
        outputFile.close();
        return true;
    }
};

int main(int argc, char* argv[]) {
    string inputFile = "output/finalMachineCode.asm";
    string outputFile = "output/optimizedCode.asm";
    
    if (argc > 1) {
        inputFile = argv[1];
    }
    if (argc > 2) {
        outputFile = argv[2];
    }
    
    CodeOptimizer optimizer;
    
    if (!optimizer.loadFile(inputFile)) {
        return 1;
    }
    
    optimizer.optimize();
    
    if (!optimizer.saveFile(outputFile)) {
        return 1;
    }
    
    return 0;
}
