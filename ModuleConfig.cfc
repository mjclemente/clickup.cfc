component {

  this.title = "ClickUp API";
  this.author = "Matthew J. Clemente";
  this.webURL = "https://github.com/mjclemente/clickup.cfc";
  this.description = "A wrapper for the ClickUp Project Management API";

  function configure(){
    settings = {
      apiKey = '', // Required
      baseUrl = 'https://api.clickup.com/api/v1', // Default value in init
      includeRaw = false // Default value in init
    };
  }

  function onLoad(){
    binder.map( "clickup@clickupcfc" )
      .to( "#moduleMapping#.clickup" )
      .asSingleton()
      .initWith(
        apiKey = settings.apiKey,
        baseUrl = settings.baseUrl,
        includeRaw = settings.includeRaw
      );
  }

}