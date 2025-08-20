options sasmstore=LaTeXSAS mstored;/**I have made a permanent library available at start up
                                  to store these macros...**/

/**padding is set in SAS.STY, so make the default match its setting there**/
/**lineWidth=.025 is the Latex default, but changable if changed
                      in SAS.STY*/
%macro OutputClean(OutputPath=,OutputName=,padding=0.1,lineWidth=0.025) / store;
filename output "&OutputPath";

data _null_;
  retain name lastWidth;
  length currentSpec $10;
  infile output("&OutputName.RawTables.rtf") truncover;
  input @1 rtfLine $2000.; /**changed this to fixed column**/
  
  if index(rtfLine,'%<*') ne 0 then do;
      name = compress(scan(rtfLine,2,'<>'),'*');
      output+1;
  end;
  if name ne '' and index(rtfLine,'\bkmkstart IDX') ne 0 then do;
      table+1;
      row=0;
  end;
  if name ne '' and index(rtfLine,'\trowd') ne 0 then do;
      row+1;
      col=0;
  end;
  if substr(rtfLine,1,8) in ('\clbrdrt','\clbrdrb') and table ne 0 then do;
      if col=0 then lastWidth=0;
      col+1;
      loc=index(rtfLine,'\cellx')+6;
      width=input(substr(rtfLine,loc),best.)-lastWidth;
      call symput(cats('O',output,'T',table,'R',row,'C',col),width/566.92914234);
      lastWidth=lastWidth+width;
  end;
  if index(rtfLine,'%</') ne 0 then do;
      name = ' ';
      table=0;
      row=0;
      col=0;
      loc=0;
  end;
run;


data _null_;
  length currentSpec $10;
  infile output("&OutputName.RawTables.tex") truncover;
  input @1 texLine $2000.; /**changed this to fixed column**/
  retain TableRows;    

  file output("&OutputName.FinalTables.tex");
  if anyalpha(texLine) gt 0 then do;
      if index(texLine,'\sasbyline') then put texLine;
      if sum(index(texLine,'\sascontents'),index(texLine,'\pagebreak')) eq 0 then do;
          if index(lowcase(compress(texLine)),'tablerows=') gt 0 then TableRows = input(compress(texLine,,'kd'),best10.);
          if index(texLine,'\%<*') ne 0 then do;
              texLine = substr(texLine,2);
              c = 0;
              if TableRows eq . then TableRows = 1000;
              output+1;
              table=0;
              put texLine;
          end;
          else if index(texLine,'proctitle') ne 0 then do;
              put texLine;
          end;
          else if index(texLine,'\%</') ne 0 then do;
              texLine = substr(texLine,2);
              put texLine;
          end;
          else if index(texLine,'\begin{sastable}') ne 0 then do;
              put texLine;output;
              table+1;
              tableRow=1;
              col=0;
          end;/**start of table**/
          else if index(texLine,'\hline') ne 0 or index(texLine,'\endhead') ne 0 then do;
              if tableRow le TableRows+1 then put texLine;output;
          end;/**horizontal lines or end of header commands**/
          else if index(texLine,'\multicolumn') ne 0 then do;
              lastNonBlank=substr(strip(reverse(texLine)),1,1);
              if lastNonBlank eq '&' then do;
                  col+1;
                  currentCols=input(scan(texLine,2,'{}'),best.);
                  width=symget(cats('O',output,'T',table,'R',tableRow,'C',col))+(currentCols-1)*&lineWidth+2*(currentCols-1)*&padding;
                  widthParm=cats('{',width,'cm}');
                  *widthParm=cats('{',put(currentCols*&width+(currentCols-1)*.025+2*(currentCols-1)*&padding,best.),'cm}');
                  *width=cats('{p{',put(currentCols*&width+(currentCols-1)*.025+2*(currentCols-1)*&padding,best.),'cm}}');
                  spec=(scan(texLine,5,'{}'));
                  *currentSpec=cats('{',scan(texLine,5,'{}'),'}');
                  texLine=tranwrd(texLine,cats('{',Spec,'}'),strip(widthParm));
                  texLine=tranwrd(texLine,'|S{',cats('|',upcase(spec),'{'));
                  currentCols=input(scan(texLine,2,'{}'),best.);
                  if tableRow le TableRows then put texLine;output;/***update this to use an appropriate width and p{}**/
              end;/**non-ending columns**/
              else if lastNonBlank ne '&' then do;
                  col+1;
                  currentCols=input(scan(texLine,2,'{}'),best.);
                  width=symget(cats('O',output,'T',table,'R',tableRow,'C',col))+(currentCols-1)*&lineWidth+2*(currentCols-1)*&padding;
                  widthParm=cats('{',width,'cm}');
                  *widthParm=cats('{',put(currentCols*&width+(currentCols-1)*.025+2*(currentCols-1)*&padding,best.),'cm}');
                  *width=cats('{p{',put(currentCols*&width+(currentCols-1)*.025+2*(currentCols-1)*&padding,best.),'cm}}');
                  spec=(scan(texLine,5,'{}'));
                  *currentSpec=cats('{',scan(texLine,5,'{}'),'}');
                  texLine=tranwrd(texLine,cats('{',Spec,'}'),strip(widthParm));
                  texLine=tranwrd(texLine,'|S{',cats('|',upcase(spec),'{'));
                  if tableRow le TableRows then put texLine;output;/***update this to use an appropriate width and p{}**/
                  tableRow+1;
                  col=0;
              end;/**includes end of row**/
          end;/**Row definition--or part of**/
          else if index(texLine,'\end{sastable}') ne 0 then do;
              put texLine;output;
          end;/**table end**/
      end;/**Not a contents or pagebreak**/
  end;/**Non-Blank Line**/
run;
%mend;  
