options sasmstore=SASPub mstored;/**I have made a permanent library available at start up
                                  to store these macros...**/

%macro ConvertCode(CodePath=, SASCodeFile=) / store;
filename code "&CodePath";

data _null_;
    length SASLineOut LineOut $ 2000;
    infile code("&SASCodeFile..sas") truncover;
    input @1 CodeLine $char2000.;/**All reading is done preserving leading spaces 
                                    (and so is the writing) so that code indentation is preserved**/
    
        if index(lowcase(CodeLine),'.startcode') ne 0 then do;/**Check for the StartCode prefix**/
            
            LineOut = compress(codeline,'*;');
                        /**Remove the * and the semicolon**/
            
            file code("&SASCodeFile.Code.tex");
            LineOutLength=Length(LineOut);
            put LineOut $varying2000. LineOutLength;/**Put line out to TEX-converted code**/
                       
            if scan(codeline,2,'|') ne '' then SASLineOut = cats('*',scan(codeline,2,'|'));
              else SASLineOut='';
                    /**Pull the comment after the pipe, when present, and make a comment in the cleaned SAS code**/
            file code("&SASCodeFile.Cleaned.sas");
            SASLineOutLength=Length(SASLineOut);
            put SASLineOut $varying2000. SASLineOutLength;/**Put cleaned SAS code line out**/
           
            do until(lowcase(CodeLine) eq '*endcode;');/**Loop and read lines until the EndCode tag**/
                infile code("&SASCodeFile..sas") truncover;
                input @1 CodeLine $char2000.;
                if lowcase(codeline) eq '*endcode;' then do;/**If it's the end tag...**/
                    LineOut = compress(substr(CodeLine,2),';');/**remove the * and semicolon for LaTeX**/
                    SASLineOut = ' ';/**Remove for SAS**/
                    end;
                else do;
                    LineOut = transtrn(tranwrd(tranwrd(CodeLine,'/*','`\CallOut{'),'*/','}~'),'*RemoveMe ',trimn(''));
                        /**Change call out number comments in SAS code to CallOut commands for .tex,
                            unmask statements commented with RemoveMe**/
                    SASLineOut = transtrn(CodeLine,'*RemoveMe ',trimn(''));
                        /**Unmask RemoveMe for .sas, nothing else**/
                end;
                
                if not index(lowcase(CodeLine),'*dropstatement') then do;/**Skip anything tagged with dropstatement**/
                  file code("&SASCodeFile.Code.tex");
                  LineOutLength=Length(LineOut);
                  put LineOut $varying2000. LineOutLength;/**Put line out to TEX-converted code**/
                 
                  file code("&SASCodeFile.Cleaned.sas");
                  SASLineOutLength=Length(SASLineOut);
                  put SASLineOut $varying2000. SASLineOutLength;/**Put cleaned SAS code line out**/
                end;
            end;        
        end;

        /**If it's not a code section, check to see if it's a set of comments to become
            an enumerate list**/
        else if substr(CodeLine,1,4) eq '*%<*' and index(lowcase(CodeLine),'enumerate') ne 0 then do;
            LineOut = compress(substr(CodeLine,2),';');/**Remove the prefix and the semicolon for .tex**/
            SASLineOut='* Call Out List';/**Keep it a comment for SAS, generic header**/
           
            file code("&SASCodeFile.Code.tex");
            LineOutLength=Length(LineOut);
            put LineOut $varying2000. LineOutLength;/**Put line out to TEX-converted code**/
            
            file code("&SASCodeFile.Cleaned.sas");
            SASLineOutLength=Length(SASLineOut);
            put SASLineOut $varying2000. SASLineOutLength;/**Put cleaned SAS code line out**/
           
            do until(substr(CodeLine,1,3) eq '%</');/**Loop until we read the ending tag**/
                infile code("&SASCodeFile..sas") truncover;
                input @1 CodeLine $char2000.;
                if substr(codeline,1,3) eq '%</' then do;
                    LineOut = compress(CodeLine,';');
                    SASLineOut = ';';
                end;
                    /**If it's the end tag, remove the * and semicolon for .tex,
                       make it a semicolon only for .sas**/
                else do;
                  position=index(Codeline,'~');
                  if position eq 0 then position = 1;
                  LineOut = strip(tranwrd(substr(CodeLine,position),'~','\item '));
                    /**Start at ~ and change to the LaTeX Item command for .tex**/
                  SASLineOut = CodeLine;
                    /**Do nothing for .sas**/
                end;

                file code("&SASCodeFile.Code.tex");
                LineOutLength=Length(LineOut);
                put LineOut $varying2000. LineOutLength;/**Put line out to TEX-converted code**/
                
                file code("&SASCodeFile.Cleaned.sas");
                SASLineOutLength=Length(SASLineOut);
                put SASLineOut $varying2000. SASLineOutLength;/**Put cleaned SAS code line out**/
                
                if substr(codeline,1,3) eq '%</' then do;
                    SASLineOut = ' ';
                    put SASLineOut $varying2000. SASLineOutLength;/**Put extra blank line in cleaned SAS code**/
                end;               
            end;        
        end;
run;
%mend;
