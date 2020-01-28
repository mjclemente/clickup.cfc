/**
* ClickUp.cfc
* Copyright 2019-2020  Matthew J. Clemente, John Berquist
* Licensed under MIT (https://github.com/mjclemente/clickup.cfc/blob/master/LICENSE)
*/
component displayname="ClickUp.cfc"  {

  variables._clickupcfc_version = '1.0.2';

  public any function init(
    string apiKey = '',
    string baseUrl = "https://api.clickup.com/api/v1",
    boolean includeRaw = false,
    numeric httpTimeout = 50 ) {

    structAppend( variables, arguments );

    //map sensitive args to env variables or java system props
    var secrets = {
      'apiKey': 'CLICKUP_PERSONAL_API_KEY'
    };
    var system = createObject( 'java', 'java.lang.System' );

    for ( var key in secrets ) {
      //arguments are top priority
      if ( variables[ key ].len() ) continue;

      //check environment variables
      var envValue = system.getenv( secrets[ key ] );
      if ( !isNull( envValue ) && envValue.len() ) {
        variables[ key ] = envValue;
        continue;
      }

      //check java system properties
      var propValue = system.getProperty( secrets[ key ] );
      if ( !isNull( propValue ) && propValue.len() ) {
        variables[ key ] = propValue;
      }
    }

    //declare file fields to be handled via multipart/form-data **Important** this is not applicable if payload is application/json
    variables.fileFields = [];

    variables.utcBaseDate = dateAdd( "l", createDate( 1970,1,1 ).getTime() * -1, createDate( 1970,1,1 ) );

    return this;
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/user
  * @hint Get the user that belongs to this token
  */
  public struct function getAuthorizedUser() {
    return apiCall( 'GET', '/user' );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/team/get-authorized-teams
  * @hint Get the authorized teams for this token
  */
  public struct function listAuthorizedTeams() {
    return apiCall( 'GET', '/team' );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/team/get-team-by-id
  * @hint Get a team's details. This team must be one of the authorized teams for this token.
  */
  public struct function getTeamById( required numeric id ) {
    return apiCall( 'GET', '/team/#id#' );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/space/get-team's-spaces
  * @hint Get a team's spaces. This team must be one of the authorized teams for this token.
  */
  public struct function listSpacesByTeamId( required numeric id ) {
    return apiCall( 'GET', '/team/#id#/space' );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/project/get-space's-projects
  * @hint Get a space's projects. The projects' lists will also be included.
  */
  public struct function listProjectsBySpaceId( required numeric id ) {
    return apiCall( 'GET', '/space/#id#/project' );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/list
  * @hint Create a list under a project
  * @project_id Project ID to create the list under
  */
  public struct function createList( required numeric project_id, required string name ) {
    var payload = { 'name': name };
    return apiCall( 'POST', '/project/#project_id#/list', {}, payload );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/list/edit-list
  * @hint Edit a list by ID.
  */
  public struct function editList( required numeric id, required string name ) {
    var payload = { 'name': name };
    return apiCall( 'PUT', '/list/#id#', {}, payload );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/task/get-tasks
  * @hint Get a list of a team's projects, with numerous available filters. Read the docs to find out more about them. Date filters are automatically converted to UTC, so you don't need to
  */
  public struct function listTasks( required numeric team_id, struct filters = {} ) {
    var dateFilters = [ 'due_date_gt', 'due_date_lt', 'date_created_gt', 'date_created_lt', 'date_updated_gt', 'date_updated_lt' ];
    var params = filters.map(
      function( key, value ) {

        if( dateFilters.find( key ) && !isValid( 'integer', value ) )
          return getUTCTimestamp( value );
        else
          return value;
      }
    );
    return apiCall( 'GET', '/team/#team_id#/task', params );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/task/create-task-in-list
  * @hint Create a task in a list
  * @task this should be an instance of the `helpers.task` component. However, if you want to create and pass in the struct or JSON yourself, you can.
  * @list_id Not required in most cases. Because tasks must be added to lists, you can include the list ID in the Task component or struct. However, if you provide raw JSON for the task or don't include the list ID in the Task component/struct, then you must provide it here. When this argument is present, it takes precedence.
  * @returns the id of the task (string)
  */
  public struct function createTask( required any task, numeric list_id ) {
    var payload = {};
    var listId = '';

    if( isValid( 'component', task ) ) {

      payload = task.build();
      listId = task.getList_id();

    } else {

      payload = task;
      if( isStruct( task ) && task.keyExists( 'list_id' ) )
        listId = task.list_id;

    }

    if ( arguments.keyExists( 'list_id' ) )
      listId = list_id;

    return apiCall( 'POST', '/list/#listId#/task', {}, payload );
  }

  /**
  * https://clickup.docs.apiary.io/#reference/0/task/edit-task
  * @hint Edit an existing task
  * @task this should be an instance of the `helpers.task` component. However, if you want to create and pass in the struct or JSON yourself, you can.
  * @returns the id of the task (string)
  */
  public struct function editTask( required string id, required any task ) {
    var payload = {};

    if( isValid( 'component', task ) )
      payload = task.build( edit = true );
    else
      payload = task;

    return apiCall( 'PUT', '/task/#id#', {}, payload );
  }




  // PRIVATE FUNCTIONS
  private struct function apiCall(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    any payload = '',
    struct headers = { } )  {

    var fullApiPath = variables.baseUrl & path;
    var requestHeaders = getBaseHttpHeaders();
    requestHeaders.append( headers, true );

    var requestStart = getTickCount();
    var apiResponse = makeHttpRequest( httpMethod = httpMethod, path = fullApiPath, queryParams = queryParams, headers = requestHeaders, payload = payload );

    var result = {
      'responseTime' = getTickCount() - requestStart,
      'statusCode' = listFirst( apiResponse.statuscode, " " ),
      'statusText' = listRest( apiResponse.statuscode, " " ),
      'headers' = apiResponse.responseheader
    };

    var parsedFileContent = {};

    // Handle response based on mimetype
    var mimeType = apiResponse.mimetype ?: requestHeaders[ 'Content-Type' ];

    if ( mimeType == 'application/json' && isJson( apiResponse.fileContent ) ) {
      parsedFileContent = deserializeJSON( apiResponse.fileContent );
    } else if ( mimeType.listLast( '/' ) == 'xml' && isXml( apiResponse.fileContent ) ) {
      parsedFileContent = xmlToStruct( apiResponse.fileContent );
    } else {
      parsedFileContent = apiResponse.fileContent;
    }

    //can be customized by API integration for how errors are returned
    //if ( result.statusCode >= 400 ) {}

    //stored in data, because some responses are arrays and others are structs
    result[ 'data' ] = parsedFileContent;

    if ( variables.includeRaw ) {
      result[ 'raw' ] = {
        'method' : ucase( httpMethod ),
        'path' : fullApiPath,
        'params' : parseQueryParams( queryParams ),
        'payload' : parseBody( payload ),
        'response' : apiResponse.fileContent
      };
    }

    return result;
  }

  private struct function getBaseHttpHeaders() {
    return {
      'Accept' : 'application/json',
      'Content-Type' : 'application/json',
      'Authorization' : '#variables.apiKey#',
      'User-Agent' : 'ClickUp.cfc/#variables._clickupcfc_version# (ColdFusion)'
    };
  }

  private any function makeHttpRequest(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    struct headers = { },
    any payload = ''
  ) {
    var result = '';

    var fullPath = path & ( !queryParams.isEmpty()
      ? ( '?' & parseQueryParams( queryParams, false ) )
      : '' );

    cfhttp( url = fullPath, method = httpMethod,  result = 'result', timeout = variables.httpTimeout ) {

      if ( isJsonPayload( headers ) ) {

        var requestPayload = parseBody( payload );
        if ( isJSON( requestPayload ) )
          cfhttpparam( type = "body", value = requestPayload );

      } else if ( isFormPayload( headers ) ) {

        headers.delete( 'Content-Type' ); //Content Type added automatically by cfhttppparam

        for ( var param in payload ) {
          if ( !variables.fileFields.contains( param ) )
            cfhttpparam( type = 'formfield', name = param, value = payload[ param ] );
          else
            cfhttpparam( type = 'file', name = param, file = payload[ param ] );
        }

      }

      //handled last, to account for possible Content-Type header correction for forms
      var requestHeaders = parseHeaders( headers );
      for ( var header in requestHeaders ) {
        cfhttpparam( type = "header", name = header.name, value = header.value );
      }

    }
    return result;
  }

  /**
  * @hint convert the headers from a struct to an array
  */
  private array function parseHeaders( required struct headers ) {
    var sortedKeyArray = headers.keyArray();
    sortedKeyArray.sort( 'textnocase' );
    var processedHeaders = sortedKeyArray.map(
      function( key ) {
        return { name: key, value: trim( headers[ key ] ) };
      }
    );
    return processedHeaders;
  }

  /**
  * @hint converts the queryparam struct to a string, with optional encoding and the possibility for empty values being pass through as well
  */
  private string function parseQueryParams( required struct queryParams, boolean encodeQueryParams = true, boolean includeEmptyValues = true ) {
    var sortedKeyArray = queryParams.keyArray();
    sortedKeyArray.sort( 'text' );

    var queryString = sortedKeyArray.reduce(
      function( queryString, queryParamKey ) {

        var encodedKey = encodeQueryParams
          ? encodeUrl( queryParamKey )
          : queryParamKey;

        //standard handling of non-arrays
        if ( !isArray( queryParams[ queryParamKey ] ) ) {

          var encodedValue = encodeQueryParams && len( queryParams[ queryParamKey ] )
            ? encodeUrl( queryParams[ queryParamKey ] )
            : queryParams[ queryParamKey ];

          var parsedValue = '';
          if( includeEmptyValues || len( encodedValue ) ) {
            parsedValue = '=' & encodedValue;
          }
          var parsedParam = encodedKey & parsedValue;

        } else { //build array format query params
          var encodedKey &= '[]';

          var parsedParam = ''; //array might parse to nothing, if empty and not including empty values

          //if we're including empty values and the array is empty
          if( includeEmptyValues && !queryParams[ queryParamKey ].len() ) {
            parsedParam = encodedKey & '=';
          } else { //either not including empty values or array isn't empty

            //build array format url param out of each key
            for( var value in queryParams[ queryParamKey ] ) {
              var encodedValue = encodeQueryParams
                ? encodeUrl( value )
                : value;
              var parsedValue = encodedKey & '=' & encodedValue;
              parsedParam = parsedParam.listAppend( parsedValue, '&' );
            }

          } //end check for empty array

        } //end array/non-array handling if

        return queryString.listAppend( parsedParam, '&' );

      }, ''
    );

    return queryString.len() ? queryString : '';
  }

  private string function parseBody( required any body ) {
    if ( isStruct( body ) || isArray( body ) )
      return serializeJson( body );
    else if ( isJson( body ) )
      return body;
    else
      return '';
  }

  private string function encodeUrl( required string str, boolean encodeSlash = true ) {
    var result = replacelist( urlEncodedFormat( str, 'utf-8' ), '%2D,%2E,%5F,%7E', '-,.,_,~' );
    if ( !encodeSlash ) result = replace( result, '%2F', '/', 'all' );

    return result;
  }

  /**
  * @hint helper to determine if body should be sent as JSON
  */
  private boolean function isJsonPayload( required struct headers ) {
    return headers[ 'Content-Type' ] == 'application/json';
  }

  /**
  * @hint helper to determine if body should be sent as form params
  */
  private boolean function isFormPayload( required struct headers ) {
    return arrayContains( [ 'application/x-www-form-urlencoded', 'multipart/form-data' ], headers[ 'Content-Type' ] );
  }

  /**
  *
  * Based on an (old) blog post and UDF from Raymond Camden
  * https://www.raymondcamden.com/2012/01/04/Converting-XML-to-JSON-My-exploration-into-madness/
  *
  */
  private struct function xmlToStruct( required any x ) {

    if ( isSimpleValue( x ) && isXml( x ) )
      x = xmlParse( x );

    var s = {};

    if ( xmlGetNodeType( x ) == "DOCUMENT_NODE" ) {
      s[ structKeyList( x ) ] = xmlToStruct( x[ structKeyList( x ) ] );
    }

    if ( structKeyExists( x, "xmlAttributes" ) && !structIsEmpty( x.xmlAttributes ) ) {
      s.attributes = {};
      for ( var item in x.xmlAttributes ) {
        s.attributes[ item ] = x.xmlAttributes[ item ];
      }
    }

    if ( structKeyExists( x, 'xmlText' ) && x.xmlText.trim().len() )
      s.value = x.xmlText;

    if ( structKeyExists( x, "xmlChildren" ) ) {

      for ( var xmlChild in x.xmlChildren ) {
        if ( structKeyExists( s, xmlChild.xmlname ) ) {

          if ( !isArray( s[ xmlChild.xmlname ] ) ) {
            var temp = s[ xmlChild.xmlname ];
            s[ xmlChild.xmlname ] = [ temp ];
          }

          arrayAppend( s[ xmlChild.xmlname ], xmlToStruct( xmlChild ) );

        } else {

          if ( structKeyExists( xmlChild, "xmlChildren" ) && arrayLen( xmlChild.xmlChildren ) ) {
              s[ xmlChild.xmlName ] = xmlToStruct( xmlChild );
           } else if ( structKeyExists( xmlChild, "xmlAttributes" ) && !structIsEmpty( xmlChild.xmlAttributes ) ) {
            s[ xmlChild.xmlName ] = xmlToStruct( xmlChild );
          } else {
            s[ xmlChild.xmlName ] = xmlChild.xmlText;
          }

        }

      }
    }

    return s;
  }

  /**
  * helpful: https://www.epochconverter.com/
  * @hint API does Unix epoch in milliseconds, instead of seconds, so we multiply by 1000. Example: 1508369194377
  */
  private numeric function getUTCTimestamp( required date dateToConvert ) {
    return dateDiff( "s", variables.utcBaseDate, dateToConvert ) * 1000;
  }

}