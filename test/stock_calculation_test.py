import datetime

class StockManager:
    def __init__(self, crop_name, opening_stock):
        self.crop_name = crop_name
        self.opening_stock = opening_stock
        self.total_incoming = 0.0
        self.total_outgoing = 0.0

    @property
    def current_stock(self):
        return self.opening_stock + self.total_incoming - self.total_outgoing

    def record_incoming(self, quantity):
        assert quantity > 0, "Quantity must be positive"
        self.total_incoming += quantity

    def record_outgoing(self, quantity, allow_negative=False):
        assert quantity > 0, "Quantity must be positive"
        if not allow_negative and (self.current_stock - quantity < 0):
            raise ValueError(f"Insufficient stock! Available: {self.current_stock}, Requested: {quantity}")
        self.total_outgoing += quantity

class SubscriptionManager:
    def __init__(self, shop_id, status="trial", end_date=None, grace_end=None):
        self.shop_id = shop_id
        self.status = status
        self.end_date = end_date or (datetime.datetime.now() + datetime.timedelta(days=7))
        self.grace_end = grace_end

    def can_transact(self, current_time=None):
        now = current_time or datetime.datetime.now()
        if self.status in ["active", "trial"]:
            return now < self.end_date
        if self.status == "grace_period" and self.grace_end:
            return now < self.grace_end
        return False

def run_tests():
    # Test Stock Calculation
    stock = StockManager("Gehun", opening_stock=200.0)
    assert stock.current_stock == 200.0, "Initial stock mismatch"

    stock.record_incoming(150.0)
    assert stock.current_stock == 350.0, "Stock after incoming mismatch"

    stock.record_outgoing(80.0)
    assert stock.current_stock == 270.0, "Closing Stock formula mismatch"

    # Test Negative Stock Prevention
    try:
        stock.record_outgoing(300.0, allow_negative=False)
        assert False, "Should have thrown ValueError for negative stock"
    except ValueError as e:
        print("Negative stock guard correctly intercepted transaction:", str(e))

    # Test Subscription & Grace Period
    sub = SubscriptionManager("SHOP_1", status="trial")
    assert sub.can_transact() == True, "Trial should allow transactions"

    # Expired subscription
    past_date = datetime.datetime.now() - datetime.timedelta(days=1)
    sub_expired = SubscriptionManager("SHOP_1", status="expired", end_date=past_date)
    assert sub_expired.can_transact() == False, "Expired account must be read-only"

    # Grace Period (3 days)
    grace_future = datetime.datetime.now() + datetime.timedelta(days=2)
    sub_grace = SubscriptionManager("SHOP_1", status="grace_period", grace_end=grace_future)
    assert sub_grace.can_transact() == True, "Grace period should allow transactions"

    print("ALL STOCK & SUBSCRIPTION VERIFICATION TESTS PASSED! ✅")

if __name__ == "__main__":
    run_tests()
