package stripe

import (
	"socialapi/models/paymentmodel"

	stripe "github.com/stripe/stripe-go"
	stripePlan "github.com/stripe/stripe-go/plan"
)

// CreateDefaultPlans creates predefined default plans. This is meant
// to be run when the worker starts to be sure the plans weren't
// deleted, not called during app runtime.
func CreateDefaultPlans() error {
	for plan_id, plan := range DefaultPlans {
		_, err := CreatePlan(plan_id, plan.Name, plan.Interval, plan.Amount)
		if err != nil {
			return err
		}
	}

	return nil
}

func CreatePlan(title, name string, interval stripe.PlanInternval, amount uint64) (*paymentmodel.Plan, error) {
	planParams := &stripe.PlanParams{
		Id:       title,
		Name:     name,
		Amount:   amount,
		Currency: stripe.USD,
		Interval: interval,
	}

	plan, err := stripePlan.Create(planParams)
	if err != nil && err.Error() != ErrPlanAlreadyExists.Error() {
		return nil, err
	}

	planModel := &paymentmodel.Plan{
		Title:          title,
		ProviderPlanId: plan.Id,
		Provider:       ProviderName,
		Interval:       string(interval),
		AmountInCents:  amount,
	}

	err = planModel.Create()
	if err != nil {
		return nil, err
	}

	return planModel, nil
}

func FindPlanByTitleAndInterval(title, interval string) (*paymentmodel.Plan, error) {
	plan := &paymentmodel.Plan{
		Title:    title,
		Interval: interval,
	}

	exists, err := plan.ByTitleAndInterval()
	if err != nil {
		return nil, err
	}

	if !exists {
		return nil, nil
	}

	return plan, nil
}
