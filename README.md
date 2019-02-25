# ClickUp.cfc
A CFML wrapper for the [ClickUp API](https://clickup.com/api), which is currently in beta.

*Feel free to use the issue tracker to report bugs or suggest improvements!*

### Acknowledgements

This project borrows from the API client frameworks built by [jcberquist](https://github.com/jcberquist), such as [stripe-cfml](https://github.com/jcberquist/stripe-cfml) and [aws-cfml](https://github.com/jcberquist/aws-cfml). Because it draws on those projects, it is also licensed under the terms of the MIT license.

## Table of Contents

- [Quick Start](#quick-start)
- [`ClickUp.cfc` Reference Manual](#reference-manual)
- [Reference Manual for `helpers.task`](#reference-manual-for-helperstask)
- [Questions](#questions)
- [Contributing](#contributing)

## Quick Start
The following is a minimal example of creating a task, using the `task` helper object, without a dependency injection framework. If using DI/1 or WireBox, this would be even simpler.

```cfc
clickup = new path.to.clickup( apiKey = 'xxx' );

task = new path.to.clickup.helpers.task()
  .inList( 1234 )
  .name( 'Work on Clickup Integration' )
  .content( 'We need to integrate ClickUp with our workflow. #chr(10)# This is the first task in that process.' )
  .dueDate( now() + 14 );

clickup.createTask( task );
```

## Reference Manual

#### `getAuthorizedUser()`
Get the user that belongs to this token

#### `listAuthorizedTeams()`
Get the authorized teams for this token

#### `getTeamById( required numeric id )`
Get a team's details. This team must be one of the authorized teams for this token.

#### `listSpacesByTeamId( required numeric id )`
Get a team's spaces. This team must be one of the authorized teams for this token.

#### `listProjectsBySpaceId( required numeric id )`
Get a space's projects. The projects' lists will also be included.

#### `createList( required numeric project_id, required string name )`
Create a list under a project

#### `editList( required numeric id, required string name )`
Edit a list by Id.

#### `listTasks( required numeric team_id, struct filters = {} )`
Get a list of a team's projects. The `filters` argument is a struct, that can contain any of the parameters [listed in the documentation](https://clickup.docs.apiary.io/#reference/0/task/get-tasks). Date filters are automatically converted to UTC, so you don't need to.

#### `createTask( required any task, numeric list_id )`
Create a task in a list. The `task` argument should be an instance of the `helpers.task` component. However, if you want to create and pass in the struct or JSON yourself, you can. The `list_id` is not required in most cases. Because tasks must be added to lists, you can include the list ID in the Task component or struct. However, if you provide raw JSON for the task or don't include the list ID in the Task component/struct, then you must provide it here. When this argument is present, it takes precedence.

#### `editTask( required string id, required any task )`
Edit an existing task. The `task` argument should be an instance of the `helpers.task` component. However, if you want to create and pass in the struct or JSON yourself, you can.

## Reference Manual for `helpers.task`
This section documents every public method in the `helpers/task.cfc` file. Unless indicated, all methods are chainable.

#### `list_id( required numeric id  )`
Sets the List the Task will be created in. The `list_id` property is required to create a Task.

#### `listId( required numeric id )`
Convenience method for setting the `list_id`

#### `inList( required numeric id )`
Convenience method / fluent interface for setting the `list_id`

#### `name( required string name )`
Sets the name of the Task. The `name` property is required to create a Task.

#### `content( required string content )`
Sets the content/description of the Task. Line breaks should be passed in as actual breaks (i.e. chr(10) / chr(13) ) or similar.

#### `assignees( required any assignees )`
Set an array of assignee userIds to add to this Task. If assignees to add have already been set, this overwrites them. The `assignees` argument can be passed in as an array or comma separated list. Lists will be converted to arrays.

#### `addAssignees( required any assignees )`
Convenience method / fluent interface for setting the assignees to add.

#### `addAssignee( required numeric userId )`
Appends a single assignee userId to the Task's array of assignees to add

#### `removeAssignees( required any assignees )`
Set an array of assignee userIds to remove from this Task. If a assignees to remove have already been set, this overwrites them. The `assignees` argument can be passed in as an array or comma separated list. Lists will be converted to arrays.

#### `removeAssignee( required numeric userId )`
Appends a single assignee userId to the Task's array of assignees to remove. Pay attention to how this works. It builds an array of userIds to remove. It does not impact this object's list of assignees being added.

#### `status( required string status )`
Sets the status of the Task - these are strings.

#### `priority( required numeric priority )`
Sets the priority of the Task. The `priority` is an integer mapping as 1 : Urgent, 2 : High, 3 : Normal, 4 : Low.

#### `due_date( required date timeStamp )`
Set the date the task is due. Dates are convereted to Unix Epoch dates automatically

#### `dueDate( required date timeStamp )`
Convenience method / fluent interface for setting the `due_date`

#### `dueOn( required date timeStamp )`
Convenience method / fluent interface for setting the `due_date`

#### `build( boolean edit = false )`
The function that puts it all together and builds the JSON body for creating or editing a Task. The `edit` argument is a flag to indicate if this Task object is being used to create or edit a Task. The create and edit Task objects are structured slightly differently.

## Questions
For questions that aren't about bugs, feel free to hit me up on the [CFML Slack Channel](http://cfml-slack.herokuapp.com); I'm @mjclemente. You'll likely get a much faster response than creating an issue here.

## Contributing
:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

Before putting the work into creating a PR, I'd appreciate it if you opened an issue. That way we can discuss the best way to implement changes/features, before work is done.

Changes should be submitted as Pull Requests on the `develop` branch.

---
