/*
Name : Pagination
Description : A Pagination Component Controller
Author : Anil Kumar
Date : 25-Jan-2021

*/

public class PaginationCompController {
    public List<String> selectedFields{get;set;}//This holds the selected feilds
    public String selectedObject{get;set;}//This is used to store the selected object coming from  Controller-->>VFpage-->>Comp--->>Controller
    public String objName{get;set;}
    public String query{get;set;}//This is used to store the query
    Public ApexPages.StandardSetController ssc{get;set;} //This is standard set controller
    public List<sObject> allRecords{get;set;}//This will have all the records of the object
    public Integer Size{get;set;}//It is used get the size of the page
    public Integer pageNumber{get;set;}//It is used to get the Current page Number
    public ID recId{get;set;}// It is used to store the record id transfered from Vf component
    public String sortingValues{get;set;}//This is hold the dyanmic field values selected by user for sorting
    public String sortDir{get;set;}//This represents the direction of sorting
    public List<String> alphabetList{get;set;}//It is used to store the all the alphabet to do Alphabetical sorting
    public String alphaToBeSearch{get;set;}//This is used to get the selected alphabet choose by user to perform sorting
    public String finalQueryToBeCal;//This will store the final query
    public List<WrapperClass> listOfWrapper{get;set;}//This hold all the records extrracted from the wrapper class
    public Boolean hFields{get;set;}//This boolean vairable is used return the true or false when feilds are selected or not respectively.
    public String csvString{get;set;}//This store the String for the CSV.
    public Boolean hasRecords{get;set;}//This shows object has records or not in true or false accordingly
    public Boolean isFromSorting = false;
    public List<String> selectedFieldsListTemp{get;set;}
    public String lastUniqueDigOfObj{get;set;}//This variable will hold the last three unique digits of object and by using those keys we can create the new records for particular object
    //public String currentCol[get;set;]
    //This method will called only once autmatically by the actionfuntion component and Initialize the ssc by the query
    public void show(){  
        selectedFieldsListTemp = new List<String>();
        selectedFieldsListTemp.addAll(selectedFields);
        objName = selectedObject;
        System.debug('Inside show method ');
        System.debug('The Obj is' + SelectedObject);
        System.debug('The fields are :: ' + selectedFieldsListTemp);
        lastUniqueDigOfObj = schema.getGlobalDescribe().get(selectedObject).getDescribe().getkeyPrefix();
        //get the query in the form of the Strig 
        if(selectedObject!=null && selectedFieldsListTemp.size()>0){
            hasRecords = false;
            hFields = true;
            sortDir = 'asc';//By Default Records will be ordered in the ascending order
            alphabetList =  new list<string>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','Others','All'};   
                query = '';
            query = String.join(selectedFieldsListTemp,',');
            query = query.removeStart(',');
            query = 'Select ' + query + ' from ' + selectedObject;
            System.debug('The returned query is  ++' +query );
            ssc = new ApexPages.StandardSetController(DataBase.query(query));
            size = size==null?5:size;
            System.debug('page size is ' + size);
            ssc.setPageSize(size);
            allRecords();
        } 
        else{
            hFields = false;
            
        }
    }
    
    //This method will return the list of all Records
    public List<sObject> allRecords(){
        sRecordsSet = new Set<sObject>();
        allRecords = ssc.getRecords();
        pageNumber = ssc.getPageNumber();
        recordsInWrapper();
        return allRecords;      
    }
    
    /*============================================    Methods for Pagination   =============================================*/
    public void first(){
        ssc.first();
        allRecords();
    }
    public void next(){
        ssc.next(); 
        allRecords();   
    }
    public void previous(){
        ssc.previous();
        allRecords();
    }
    public void last(){
        ssc.last();
        allRecords();
    }
    public void pageSize(){
        ssc.setPageSize(size);
        allRecords();
    }
    public void finalPageNumber(){
        ssc.setPageNumber(pageNumber);
        allRecords();
    }
    
    //This method is to delete the single record
    public void deleteAccount() {  
        try{
            Database.delete(recId);
            show(); 
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,'Opps... You cannot delete this Record..'));   
        }  
        
    } 
    
    /*=================================== Sort the fields column wise ===============================================*/
    
    
    public void sortByColumn(){
        System.debug('The sorting value is ' + sortingValues);
        if(sortingValues==null){
            sortingValues = 'Name';
        }
        sortDir = sortDir=='asc'?'desc':'asc';
        finalQueryToBeCal = query + ' Order By ' + sortingValues + ' ' + sortDir;
        finalQueryResult(finalQueryToBeCal);  
    }
    
    public void sortByAlphabets(){
        System.debug('Inside');
        if(alphaToBeSearch == 'ALL'){
            finalQueryToBeCal = query;   
        }
        else{  
            if(alphaToBeSearch != 'Others'){
                finalQueryToBeCal = query +  ' WHERE ' + sortingValues + ' Like \'' + alphaToBeSearch + '%\''; // Escaping the inner single QUotes      
            }
            else{
                finalQueryToBeCal = query +  ' WHERE ' + sortingValues + ' <= \'a\'' + ' OR ' + sortingValues + ' <=\'0\'' ; // Escaping the inner single QUotes
                System.debug('the final$$' + finalQueryToBeCal);
            }
            
        }
        finalQueryResult(finalQueryToBeCal);          
    }
    
    /* Final Method for querying the records and it accepts the fQuery which is a final query to be queired*/
    public void finalQueryResult(String fQuery){
        isFromSorting = true;
        try{
            ssc = new ApexPages.StandardSetController(DataBase.query(fQuery));
            ssc.setpageSize(Size);
            ssc.setPageNumber(pageNumber);
            allRecords();
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Select any field.......')); 
        }
        
    }
    
    /*============================================= TO DELETE THE SELECTED RECORDS =========================================*/
    public void deleteSelectedRecords(){
        List<Id> Ids = new List<Id>();
        for(WrapperClass ob : listOfWrapper){
            if(ob.isSelected == true){
                Ids.add(ob.obj.id);
            }
        }
        //Now query the records of which we have the ID in the list
        try{
            if(Ids.size()>0){
                Integer tempSize =  Ids.size();//get the no selected records
                String s = tempSize > 1 ? ' records are deleted..' : ' record is deleted..';
                String msg = 'Great!! ' + tempSize + s;
                DataBase.delete(Ids);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,msg));
                show();
            }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Please Select any Record'));
                
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,'Opps... You cannot delete this Record..'));   
        }  
    }
    
    /*============================================= TO DOWNLOAD THE CSV ====================================================*/
    public Set<sObject> sRecordsSet;
    public String RecordsForCsv{get;set;}
    public String headerForCsv{get;set;}
    public List<String> fieldLabels;
    public void downloadCsv(){
        selectedRecords();
        fieldLabels = new List<String>();
        String tempStr = ' ';
        String str = ' ';
        for(String s : selectedFields){
            fieldLabels.add(Schema.getGlobalDescribe().get(selectedObject).getDescribe().fields.getMap().get(s).getDescribe().getLabel());
        }
        headerForCsv = String.join(fieldLabels,',');
        headerForCsv = headerForCsv + '\\n';
        for(sObject s : sRecordsSet) {
            for(String f : selectedFields){
                String rec = String.valueOf(s.get(f)) == null ? ' ' : String.valueOf(s.get(f));
                str = str + rec + ',';   
            }
            // str = str.substring(0,str.length()-1);
            str = str.removeEnd(','); 
            str = str + '\\n';
        }
        str = str.substring(1,str.length());
        RecordsForCsv = str;
    }
    /*============================================== MAINTAIN THE CHECKBOXES ===============================================*/
    public Map<Id,sObject> mapOfSelectedRecords = new Map<Id,sObject>();
    public void selectedRecords(){    
        if(listOfWrapper!=null){
            for(WrapperClass ob : listOfWrapper){
                if(ob.isSelected == true){
                    //putting all the checked records to the Map
                    mapOfSelectedRecords.put(ob.obj.id, ob.obj);
                    sRecordsSet.add(ob.obj);
                }
                else{
                    //Remove funtion is used to remove the all the Records which first selected and later deselected
                    mapOfSelectedRecords.remove(ob.obj.id);
                    if(sRecordsSet!=null)
                        sRecordsSet.remove(ob.obj);
                }
            }
        }
        System.debug('The map of selected records is ' + mapOfSelectedRecords);
    }
    
    /*============================================================= WRAPPPER CLASS =============================================================================*/    
    public class WrapperClass{
        public Boolean isSelected {get;set;}
        public sObject obj {get;set;}  
        public WrapperClass(sObject obj,Boolean isSelected)
        { 
            this.isSelected = isSelected;
            this.obj = obj;
        }
    }
    
    public List<WrapperClass> recordsInWrapper(){
        selectedRecords();//Invoke selectedRecords method every time to check the checked records
        listOfWrapper = new List<WrapperClass>();
        for(sObject sObj : allRecords){
            if(mapOfSelectedRecords.containsKey(sobj.id)){
                listOfWrapper.add(new WrapperClass(sObj,true));
            }
            else{
                listOfWrapper.add(new WrapperClass(sObj,false));
            }
        }
        system.debug('the size is::' + listOfWrapper.size());
        if(listOfWrapper.isEmpty()){
            if(isFromSorting == true){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Sorry! No Records are found for the Alphabet'));   
            }
            else{
                hasRecords = true;
                hFields = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Sorry!! This Object is not having any record.'));   
            }
        }
        return listOfWrapper;
    }      
}