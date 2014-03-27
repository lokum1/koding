class SubscriptionView extends JView

  describeSubscription = (quantity, verbPhrase) ->
    """
    Subscription for #{ KD.utils.formatPlural quantity, 'plan' } #{verbPhrase}
    """

  datePattern = "mmmm dS, yyyy, h:MM TT"

  pistachio:->
    { feeAmount, quantity, plan, status, renewAt, expires, startsAt } = @getData()

    { feeAmount } = plan  unless feeAmount

    statusNotice = switch status
      when 'active', 'modified'
        describeSubscription quantity, "is active"
      when 'canceled'
        describeSubscription quantity, "will end soon"
      when 'future'
        describeSubscription quantity, "will begin soon"
      else ''

    if "nosync" in plan.tags
      dateNotice = ""
    else
      dateNotice =
        if plan.type isnt 'single'
          switch status
            when 'active'
              "Will renew on #{dateFormat renewAt, datePattern}"
            when 'canceled'
              "Will be available till #{dateFormat (expires or renewAt), datePattern}"
            when 'future'
              "Will become available on #{dateFormat startsAt, datePattern}"
        else ''

    displayAmount = KD.utils.formatMoney feeAmount / 100

    """
      <h4>{{#(plan.title)}}</h4>
      <span class="price">#{displayAmount}</span>
      <p>#{dateNotice}</p>
    """
