/**
* clickup.cfc
* Copyright 2019 Matthew Clemente, John Berquist
* Licensed under MIT (https://github.com/mjclemente/clickup.cfc/blob/master/LICENSE)
*/
component accessors="true" {

  property name="list_id" default="" required="false" hint="List the task is assigned to. Not included in the build object";
  property name="name" default="";
  property name="content" default="";
  property name="assignees" default="" hint="Will be an array when creating tasks, and a struct of arrays when editing";
  property name="assigneesToAdd" default="" required="false" hint="Placeholder for assignees being added";
  property name="assigneesToRem" default="" required="false" hint="Placeholder for assignees being removed";
  property name="status" default="";
  property name="priority" default="";
  property name="due_date" default="";

  /**
  * @hint You can init this component with any/all properties, but you don't need to supply any. When creating and updating tasks, the following fields are required:
    * list_id,
    * name
  */
  public any function init( numeric list_id, string name, string content, array assignees, string status, numeric priority, any due_date ) {

    if ( arguments.keyExists( 'list_id' ) )
      setList_id( list_id );

    if ( arguments.keyExists( 'name' ) )
      setName( name );

    if ( arguments.keyExists( 'content' ) )
      setContent( content );

    if ( arguments.keyExists( 'assignees' ) )
      setAssigneesToAdd( assignees );
    else
      setAssigneesToAdd( [] );

    setAssigneesToRem( [] );

    if ( arguments.keyExists( 'status' ) )
      setStatus( status );

    if ( arguments.keyExists( 'priority' ) )
      setPriority( priority );

    if ( arguments.keyExists( 'due_date' ) )
      this.due_date( due_date );

    variables.utcBaseDate = dateAdd( "l", createDate( 1970,1,1 ).getTime() * -1, createDate( 1970,1,1 ) );

    return this;
  }

  /**
  * @hint Sets the List the Task will be created in. Required.
  */
  public any function list_id( required numeric id ) {
    setList_id( id );
    return this;
  }

  /**
  * @hint convenience method
  */
  public any function listId( required numeric id ) {
    return this.list_id( id );
  }

  /**
  * @hint convenience method for fluent interface
  */
  public any function inList( required numeric id ) {
    return this.list_id( id );
  }

  /**
  * @hint Sets the name of the Task. Required.
  */
  public any function name( required string name ) {
    setName( name );
    return this;
  }

  /**
  * @hint Sets the content/description of the Task. Line breaks should be passed in as actual breaks (i.e. chr(10) / chr(13) ) or similar
  */
  public any function content( required string content ) {
    setContent( content );
    return this;
  }

  /**
  * @hint Set an array of assignee userIds to add to this Task. If assignees to add have already been set, this overwrites them.
  * @assignees Can be passed in as an array or comma separated list. Lists will be converted to arrays
  */
  public any function assignees( required any assignees ) {
    if ( isArray( assignees ) )
      setAssigneesToAdd( assignees );
    else
      setAssigneesToAdd( assignees.listToArray() );

    return this;
  }

  /**
  * @hint convenience method for fluent interface
  */
  public any function addAssignees( required any assignees ) {
    return this.assignees( assignees );
  }

  /**
  * @hint Appends a single assignee userId to the Task's array of assignees to add
  */
  public any function addAssignee( required numeric userId ) {
    variables.assigneesToAdd.append( userId );
    return this;
  }

  /**
  * @hint Set an array of assignee userIds to remove from this Task. If a assignees to remove have already been set, this overwrites them.
  * @assignees Can be passed in as an array or comma separated list. Lists will be converted to arrays
  */
  public any function removeAssignees( required any assignees ) {
    if ( isArray( assignees ) )
      setAssigneesToRem( assignees );
    else
      setAssigneesToRem( assignees.listToArray() );

    return this;
  }

  /**
  * @hint Appends a single assignee userId to the Task's array of assignees to remove. Pay attention to how this works. It builds an array of userIds to remove. It does not impact this object's list of assignees being added.
  */
  public any function removeAssignee( required numeric userId ) {
    variables.assigneesToRem.append( userId );
    return this;
  }

  /**
  * @hint Sets the status of the Task - these are strings
  */
  public any function status( required string status ) {
    setStatus( status );
    return this;
  }

  /**
  * @hint Sets the priority of the Task
  * @priority The priority is an integer mapping as 1 : Urgent, 2 : High, 3 : Normal, 4 : Low.
  */
  public any function priority( required numeric priority ) {
    setPriority( priority );
    return this;
  }

  /**
  * @hint Set the date the task is due. Dates are convereted to Unix Epoch dates automatically
  */
  public any function due_date( required date timeStamp ) {
    setDue_date( getUTCTimestamp( timeStamp ) );

    return this;
  }

  /**
  * @hint convenience method for fluent interface
  */
  public any function dueDate( required date timeStamp ) {
    return this.due_date( timeStamp );
  }

  /**
  * @hint convenience method for fluent interface
  */
  public any function dueOn( required date timeStamp ) {
    return this.due_date( timeStamp );
  }


  /**
  * @hint A very simple build() that does not require any custom serialization methods via onMissingMethod(), like other helpers.
  * @edit a flag to indicate if this task object is being used to create or edit a task. The create and edit task objects are structured slightly differently.
  */
  public string function build( boolean edit = false ) {

    if( !edit ) { //create

      setAssignees( getAssigneesToAdd() );

    } else { //edit

      var assigneeEdits = {};

      if( getAssigneesToAdd().len() )
        assigneeEdits[ 'add' ] = getAssigneesToAdd();
      if( getAssigneesToRem().len() )
        assigneeEdits[ 'rem' ] = getAssigneesToRem();

      setAssignees( assigneeEdits );
    }

    var body = '';
    var properties = getPropertyValues();
    var count = properties.len();

    properties.each(
      function( property, index ) {
        body &= '"#property.key#": ' & serializeJSON( property.value ) & '#index NEQ count ? "," : ""#';
      }
    );

    return '{' & body & '}';
  }

  /**
  * helpful: https://www.epochconverter.com/
  * @hint API does Unix epoch in milliseconds, instead of seconds, so we multiply by 1000. Example: 1508369194377
  */
  private numeric function getUTCTimestamp( required date dateToConvert ) {
    return dateDiff( "s", variables.utcBaseDate, dateToConvert ) * 1000;
  }

  /**
  * @hint converts the array of properties to an array of their keys/values, while filtering those that have not been set
  */
  private array function getPropertyValues() {

    var propertyValues = getProperties().map(
      function( item, index ) {
        return {
          "key" : item.name,
          "value" : getPropertyValue( item.name )
        };
      }
    );

    return propertyValues.filter(
      function( item, index ) {
        if ( isStruct( item.value ) )
          return !item.value.isEmpty();
        else
          return len( item.value );
      }
    );
  }

  private array function getProperties() {

    var metaData = getMetaData( this );
    var properties = [];

    for( var prop in metaData.properties ) {
      if( !prop.keyExists( 'required' ) || prop.required )
        properties.append( prop );
    }

    return properties;
  }

  private any function getPropertyValue( string key ){
    var method = this["get#key#"];
    var value = method();
    return value;
  }
}