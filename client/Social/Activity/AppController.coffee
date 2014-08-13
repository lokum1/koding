class ActivityAppController extends AppController


  KD.registerAppClass this,
    name         : 'Activity'
    searchRoute  : '/Activity?q=:text:'


  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'

    warn 'dock.getView().show()'

    @on 'LazyLoadThresholdReached', @getView().bound 'lazyLoadThresholdReached'


  post: (options = {}, callback = noop) ->

    {body, payload} = options
    {socialapi} = KD.singletons

    socialapi.message.post {body, payload}, callback


  edit: (options = {}, callback = noop) ->

    {id, body} = options
    {socialapi} = KD.singletons

    socialapi.message.edit {id, body}, callback


  reply: ({activity, body}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.reply {body, messageId}, callback


  delete: ({id}, callback) ->

    {socialapi} = KD.singletons
    socialapi.message.delete {id}, callback


  listReplies: ({activity, from, limit}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.listReplies {messageId, from, limit}, callback


  sendPrivateMessage: (options = {}, callback = noop) ->

    {socialapi} = KD.singletons
    socialapi.message.sendPrivateMessage options, callback


  firstFetch = yes

  fetch: ({channelId, from, limit}, callback = noop) ->

    id = channelId
    {socialapi} = KD.singletons
    {socialApiChannelId} = KD.getGroup()
    id ?= socialApiChannelId

    # FIXME
    # remove this once there are koding and public channels in default db setup
    # otherwise this will continue pollute your feeds - SY
    if firstFetch
      {generatePassword, getRandomNumber} = KD.utils
      # KD.singletons.socialapi.message.post body: "Hello world, #{generatePassword getRandomNumber(7), yes} #koding #public", log

    if firstFetch and socialapi.getPrefetchedData('navigated').length > 0
      messages   = socialapi.getPrefetchedData 'navigated'
      KD.utils.defer ->  callback null, messages
    else
      log id, firstFetch, 'hello'
      socialapi.channel.fetchActivities {id, from, limit}, callback

    firstFetch = yes


  #
  # LEGACY
  #

  createContentDisplay:(activity, callback = ->)->

    contentDisplay = new ContentDisplayStatusUpdate
      title : 'Status Update'
      type  : 'status'
    , activity

    KD.singleton('display').emit 'ContentDisplayWantsToBeShown', contentDisplay
    @utils.defer -> callback contentDisplay


  fetchActivitiesProfilePage:(options, callback)->

    {originId} = options
    options.to = options.to or @profileLastTo or Date.now()
    if KD.checkFlag 'super-admin'
      appStorage = new AppStorage 'Activity', '1.0'
      appStorage.fetchStorage (storage)=>
        options.withExempt = appStorage.getValue('showLowQualityContent') or off
        @fetchActivitiesProfilePageWithExemptOption options, callback
    else
      options.withExempt = false
      @fetchActivitiesProfilePageWithExemptOption options, callback


  fetchActivitiesProfilePageWithExemptOption:(options, callback)->

    {JNewStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JNewStatusUpdate.fetchProfileFeed options, (err, activities)=>
      return @emit "activitiesCouldntBeFetched", err  if err

      if activities?.length > 0
        lastOne = activities.last.meta.createdAt
        @profileLastTo = (new Date(lastOne)).getTime()
      callback err, activities
