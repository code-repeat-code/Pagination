public class PaginationController {
    /*----------------------------------------------------------        FOR OBJECTS           ---------------------------------------------*/
    //It will return the KeySet of all the present objects in the org
    public Map<String,Schema.SObjectType> allObjectsMap{get;set;}
    // Now create a list which will hold the only objects
    public List<String> objList{get;set;}
    public String selectedObject{get;set;}
    //Created a selectoption for the picklist of objects
    public List<SelectOption> objects{get;set;}
    public String objName{get;set;}    
    public Boolean hasFields{get;set;}
    public boolean temp{get;set;}
    /* --------------------------------------------------               FOR FIELDS        ----------------------------------------------------*/
    
    
    //AllFeild is a list which will contain the all the fields
    public List<String> allFields{get;set;}
    //A map which will have the fields 
    public Map <String, Schema.SObjectField> fieldMap{get;set;} //We can use FieldMap to just extract all the fields for the selected object and also to get the label of the field fromt the api name (i.e FieldMap.get(api__name).getDdescribe().getLabel()
    //Now create select Option to pass that on the VF page
    
    // Created Two select Option fields which obtains the order or the added or removed fields in the picklist
    public List<SelectOption> selectedFieldsInOptionsList{get;set;}
    public List<SelectOption> notSelectedFieldsInOptionsList{get;set;}
    
    //These two lists are declared  because at the same time we have to perform two operations(i.e ADD & REMOVE) on the same list for multiple fields  so for the easyness we can add or remove list of selected fields
    public List<String> selectedFields{get;set;}
    public List<String> notSelectedFields{get;set;}
    
    //These two list's are for the items or fields which are to be selected from page to be add or remove 
    public List<String> fieldsToBeRemoved{get;set;}
    public List<String> fieldsToBeAdd{get;set;}
    public Boolean hasSelectedFields{get;set;}
    
    
    /*---------------------------------------------------------------           FOR RECORDS         -----------------------------------------------------------------------------------*/
    
    
  
    //Now create contructor to initiate this
    public PaginationController(){
        hasSelectedFields = false;
        objects = new List<SelectOption>();
        objList = new List<String>();
        allObjectsMap = Schema.getGlobalDescribe(); //Fetching the Map of Objects with their description
        objList.addAll(allObjectsMap.keySet());     // Fecthing the KeySet from Map(i.e Objects) and adding them to the list
        objList.sort();
        //Now create a picklist or select list to select the objects from the list 
        // Map.get(API__NAME).getDescribe().getLabel 
        objects.add(new SelectOption('None','-None-')); // By default add None at the top level        
        for(String objName : objList){
            if(objName.endsWith('__c') || (objName == 'Account' || objName == 'Asset' || objName == 'Campaign' || objName == 'Case' || objName == 'Contact' || objName == 'Contract' || objName == 'Idea' || objName == 'Lead' ||objName == 'Opportunity' || objName == 'Order' || objName == 'Solution' || objName == 'User')){
                SelectOption obj = new SelectOption(objName,allObjectsMap.get(objName).getDescribe().getLabel());//first ObjLabel is for the value of object andn another is for the Label name
                objects.add(obj);
            }
            
        }
        
        /*---------------------------------------------FOR FIELD INITIALISATION---------------------------------------------------*/
        
        allFields = new List<String>();
        selectedFieldsInOptionsList = new List<SelectOption>();
        notSelectedFieldsInOptionsList = new List<SelectOption>();
        selectedFields = new List<String>();
        notSelectedFields = new List<String>();
        fieldsToBeAdd = new List<String>();
        fieldsToBeRemoved = new List<String>();
    }
    
    //Create a Method which will show all the fields of selected object dynamically  
    public void details(){
		selectedFields.clear();
        if(notSelectedFields != null || selectedFields!=null){
            notSelectedFields.clear();
            SelectedFields.clear();       
        }
        if(selectedObject == 'None'){
            hasFields = false;
            temp = false;
            notSelectedFields.clear();
            SelectedFields.clear();
            objName = '';
            display();
        }
        else{
            temp = false;
            objName = allObjectsMap.get(selectedObject).getDescribe().getLabel();
            fieldMap = allObjectsMap.get(selectedObject).getDescribe().fields.getMap();  
            allFields.addAll(fieldMap.keySet());
            allFields.sort();
            notSelectedFields.addAll(allFields);
            display(); 
           // process();     
        }
        
    } 
    
    
    /*================================DYNAMIC DISPLAY METHOD(It can Handle both cases for Adding & Deletion)=========================================*/
    public void display(){
        hasSelectedFields = selectedFields.isEmpty();
        allfields.clear();//Clear the allFields list if to fetch the fields for the updated selected Object
        selectedFieldsInOptionsList.clear();
        notselectedFieldsInOptionsList.clear();
        System.debug('Inside the display');
        System.debug('The size of selected Fields is ' + selectedFields.size());
        hasFields = selectedFields.size() > 0 ? true:false;
        for(String fieldApi : notSelectedFields){
            String fieldLabel = fieldMap.get(fieldApi).getDescribe().getLabel();
            if(fieldMap.get(fieldApi).getDescribe().isSortable() && fieldMap.get(fieldApi).getDescribe().isupdateable()){
           		 notselectedFieldsInOptionsList.add(new SelectOption(fieldApi,fieldLabel));//to fetch the field label
            }
        }
        for(String fieldApi : selectedFields){
            String fieldLabel = fieldMap.get(fieldApi).getDescribe().getLabel();
            selectedFieldsInOptionsList.add(new SelectOption(fieldApi,fieldLabel));
        }
        
    }
    
    /*===============================================METHODS FOR THE ADD & REMOVE BUTTON ============================================================*/ 
    
    public String newObj{get;set;}
    public void addFields(){
        // Remove all the selected fields(Selected by user as a list) 
        selectedFields.addAll(fieldsToBeAdd);//Add those fields to the right picklist
        for(String addingfeilds : fieldsToBeAdd){  
            notSelectedFields.remove(notSelectedFields.indexOf(addingfeilds));
            notselectedFields.sort();
        }
       
        hasSelectedFields = selectedFields.isEmpty();
        display(); 
    }
    
    public void removeFields(){
        notSelectedFields.addAll(fieldsToBeRemoved);//All the fields the to the notSelectedFields set to again add to the default feild side
        notselectedFields.sort();
        //After adding fields the default fields side now remove them the set which is selectedFields set. 
        for(String s : fieldsToBeRemoved){
            selectedFields.remove(selectedFields.indexOf(s));
            selectedFields.sort();
        } 
        hasSelectedFields = selectedFields.isEmpty();
        display();
    } 
    
    /*=============================================================================================================================================*/   
    
    //Resetting the current Page 
    public PageReference reset() {
        PageReference np = new PageReference(System.currentPageReference().getURL());
        np.setRedirect(true);
        return np;
    }
    
    /*============================================Create A Dynamic Query to Fetch the records as per object and Field selection by the user*/
    public String finalObjectName{get;set;}
    public List<String> finalSelectedFieldsList{get;set;}
    Integer i = 1;
    public void process(){
        if(selectedFields.isEmpty()){
            temp = false;
        }
        else{
            System.debug('Inside the else Part');
            temp = true;
            System.debug('the I value is :: ' + i);
            finalSelectedFieldsList = new List<String>();
            finalObjectName = selectedObject;
            System.debug('final object is ' + finalObjectName);
            finalSelectedFieldsList.addAll(selectedFields);
            System.debug('final fields are ' + finalSelectedFieldsList);
        }
    }
 }