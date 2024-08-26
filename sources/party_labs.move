module party_labs::party_labs {

    use std::string::{String};
    use sui::table;

    const ERemintError: u64 = 0;
    const ENoCapError: u64 = 1;

    public struct PartyManage has key, store {
        id: UID,
        raver_map: table::Table<address, Raver>,
        events: table::Table<String, Event>,
    }

    public struct Raver has store {
        name: String,
        owner: address,
        events: vector<String>,
    }

    public struct Event has key, store {
        id: UID,
        name: String,
        attendee: vector<address>,
        attendee_map: table::Table<address, AttendedEvent>,
    }

    public struct Router has key, store {
        id: UID,
        owner: address,
        event: String,
        score: u64,
    }

    public struct RouterInfo {
        info: u64,
    }

    public struct AttendedEvent has store {
        attendee: address,
        witness: address,
    }

    public struct AdminCap has key {
        id: UID,
    }

    public struct EventCap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap{id: object::new(ctx)}, @admin_address);
        transfer::share_object(
            PartyManage{
                id: object::new(ctx),
                raver_map: table::new<address, Raver>(ctx),
                events: table::new<String, Event>(ctx),
            }
        );
    }

    public entry fun mint_raver(name: String, party: &mut PartyManage, ctx: &mut TxContext) {
        if (table::contains<address, Raver>(& party.raver_map, tx_context::sender(ctx))) {
            abort ERemintError
        } else {
            let raver = Raver{
            name: name,
            owner: tx_context::sender(ctx),
            events: vector::empty()
            };
            table::add(&mut party.raver_map, tx_context::sender(ctx), raver);
        }
    }

    public entry fun create_event_cap(_: &AdminCap, to: address, ctx: &mut TxContext) {
        transfer::transfer(EventCap{id: object::new(ctx)}, to);
    }

    public entry fun create_event(_: EventCap, name: String, party: &mut PartyManage, ctx: &mut TxContext) {
        if (table::contains<String, Event>(& party.events, name)) {
            abort ERemintError
        } else {
            let event = Event{
            id: object::new(ctx),
            name: name,
            attendee: vector::empty(),
            attendee_map: table::new<address, AttendedEvent>(ctx),
            };
            table::add(&mut party.events, name, event);
        };
        let EventCap {id} = _;
        object::delete(id);
    }

    #[allow(unused_variable)]
    public entry fun witness(e: String, r: address, w: address, party: &mut PartyManage, ctx: &mut TxContext) {
        if (w != tx_context::sender(ctx)) {
            abort ENoCapError
        } else {
            let event = table::borrow_mut<String, Event>(&mut party.events, e);
            let witness = table::borrow<address, Raver>(& party.raver_map, w);
            let attendee = table::borrow<address, Raver>(& party.raver_map, r);
            if (table::contains<address, AttendedEvent>(& event.attendee_map, attendee.owner)) {
                abort ERemintError
            } else {
                let router = Router{
                    id: object::new(ctx),
                    owner: r,
                    event: e,
                    score: 0,
                };

                transfer::transfer(router, r);
                
                let a_event = AttendedEvent{
                attendee: attendee.owner,
                witness: witness.owner,
                };
                
                vector::push_back(&mut event.attendee, r);
                table::add(&mut event.attendee_map, attendee.owner, a_event);
                
                let Raver {name, owner, events} = attendee;
                let Raver {name, owner, events} = witness;

                let attendee = table::borrow_mut<address, Raver>(&mut party.raver_map, r);  
                vector::push_back(&mut attendee.events, e);
            }
        }   
    }

    public fun init_router() : RouterInfo {
        RouterInfo{
            info: 0,
        }
    }

    public fun close_router(router_info: RouterInfo, router: &mut Router) {
        let RouterInfo { info } = router_info;
        router.score = router.score + info;
    }

    public fun routing(router_info: &mut RouterInfo) {
        let score_change = voidtest();
        router_info.info = router_info.info + score_change;
    }

    public fun voidtest(): u64 { 5 }
}