#[test_only]
module sui_attendance_nft::attendance_test {
	use sui_attendance_nft::command::{mint_and_transfer_bulk};
	use sui_attendance_nft::attendance::{mint_and_transfer, Attendance, receive};
	use sui_attendance_nft::meet::{AdminCap,Meet,new};
	use sui::coin::{mint_for_testing, Coin};

	use std::debug;
	#[test_only] use sui::test_scenario;
	#[test_only]
	public struct TestCoin {}

	#[test]
    fun test_mint() {
		let mut scenario = test_scenario::begin(@alice);
		{
            sui_attendance_nft::meet::init_for_testing(scenario.ctx());
            sui_attendance_nft::attendance::init_for_testing(scenario.ctx());
		};
		scenario.next_tx(@alice);

		{
			let adminCap = scenario.take_from_sender<AdminCap>();
			let meet = new(
				&adminCap,
				b"Rochester".to_string(),
				b"2024-04-26".to_string(),
				b"test description".to_string(),
				option::none(),
				scenario.ctx()
			);
			scenario.return_to_sender(adminCap);
			transfer::public_transfer(meet, @bob);
		};
		scenario.next_tx(@bob);

		{
			let mut meet = scenario.take_from_sender<Meet>();

			mint_and_transfer(
				&mut meet,
				b"Bob".to_string(),
				b"description".to_string(),
				b"image_url".to_string(),
				1,
				@bob,
				scenario.ctx(),
			);

			scenario.return_to_sender(meet);
		};
		scenario.next_tx(@bob);

		{
			let a = scenario.take_from_sender<Attendance>();
			assert!(a.name() == b"Bob".to_string(), 3);
            scenario.return_to_sender(a);

			let mut meet = scenario.take_from_sender<Meet>();
			mint_and_transfer(
				&mut meet,
				b"Fran".to_string(),
				b"Fran description".to_string(),
				b"image_url".to_string(),
				2,
				@fran,
				scenario.ctx(),
			);

			scenario.return_to_sender(meet);
		};
		scenario.next_tx(@fran);

        let a = scenario.take_from_sender<Attendance>();
        assert!(a.name() == b"Fran".to_string(), 3);
        scenario.return_to_sender(a);


		scenario.end();
	}

	#[test]
	fun test_mint_bulk() {
		let mut scenario = test_scenario::begin(@alice);
		{
			sui_attendance_nft::meet::init_for_testing(scenario.ctx());
			sui_attendance_nft::attendance::init_for_testing(scenario.ctx());
		};
		scenario.next_tx(@alice);

		{
			let adminCap = scenario.take_from_sender<AdminCap>();
			let meet = new(
				&adminCap,
				b"Rochester".to_string(),
				b"2024-04-26".to_string(),
				b"test description".to_string(),
				option::none(),
				scenario.ctx()
			);
			scenario.return_to_sender(adminCap);
			transfer::public_transfer(meet, @bob);
		};

		scenario.next_tx(@bob);
		{
			let mut meet = scenario.take_from_sender<Meet>();
			let name = b"Bob".to_string();
			let desc = b"description".to_string();
            let image_id = b"image_url".to_string();
			let tiers = 1;
			let to_addr_vec = vector[@bob, @fran];

			mint_and_transfer_bulk(
				&mut meet,
				name,
				desc,
				image_id,
				tiers,
				to_addr_vec,
				scenario.ctx(),
			);

			scenario.return_to_sender(meet);
		};
        scenario.next_tx(@bob);
        assert!(scenario.ids_for_sender<Attendance>().length() == 1, 0);

        scenario.next_tx(@fran);
        assert!(scenario.ids_for_sender<Attendance>().length() == 1, 1);

		scenario.end();
	}

    #[test]
    fun test_receive() {
		let mut scenario = test_scenario::begin(@alice);
		{
			sui_attendance_nft::meet::init_for_testing(scenario.ctx());
			sui_attendance_nft::attendance::init_for_testing(scenario.ctx());
		};
		scenario.next_tx(@alice);

		{
			let adminCap = scenario.take_from_sender<AdminCap>();
			let meet = new(
				&adminCap,
				b"Rochester".to_string(),
				b"2024-04-26".to_string(),
				b"test description".to_string(),
				option::none(),
				scenario.ctx()
			);
			scenario.return_to_sender(adminCap);
			transfer::public_transfer(meet, @bob);
		};
		scenario.next_tx(@bob);

		{
			let mut meet = scenario.take_from_sender<Meet>();

			mint_and_transfer(
				&mut meet,
				b"Bob".to_string(),
				b"description".to_string(),
				b"image_url".to_string(),
				1,
				@bob,
				scenario.ctx(),
			);

			scenario.return_to_sender(meet);
		};
		scenario.next_tx(@bob);
        let coin_id;

		{
			let a = scenario.take_from_sender<Attendance>();
			assert!(a.name() == b"Bob".to_string(), 3);

			let new_coin = mint_for_testing<TestCoin>(1000, scenario.ctx());
            coin_id = object::id(&new_coin);
			transfer::public_transfer(new_coin, a.id().to_address());

			scenario.return_to_sender(a);
		};
        let effects = scenario.next_tx(@bob);

        {
            let prev_transfers = effects.transferred_to_account();

			let mut a = scenario.take_from_sender<Attendance>();
            // Assert the Coin is now a child object of the Attendance
            assert!(prev_transfers[&coin_id].to_id() == a.id(), 1);
			let ticket = test_scenario::most_recent_receiving_ticket<Coin<TestCoin>>(&a.id());

            let test_coin = receive<Coin<TestCoin>>(&mut a, ticket);
            transfer::public_transfer(test_coin, @alice);

            let effects = scenario.next_tx(@bob);
            let receive_res = &effects.transferred_to_account();
            assert!(receive_res[&coin_id] == @alice, 2);

            scenario.return_to_sender(a);
        };

        scenario.end();
    }

	#[test]
	#[expected_failure]
    fun test_freeze_meet() {
		let mut scenario = test_scenario::begin(@alice);
		{
            sui_attendance_nft::meet::init_for_testing(scenario.ctx());
            sui_attendance_nft::attendance::init_for_testing(scenario.ctx());
		};

		scenario.next_tx(@alice);
		{
			let adminCap = scenario.take_from_sender<AdminCap>();
			let meet = new(
				&adminCap,
				b"Rochester".to_string(),
				b"2024-04-26".to_string(),
				b"test description".to_string(),
				option::none(),
				scenario.ctx()
			);
			scenario.return_to_sender(adminCap);
			transfer::public_transfer(meet, @alice);
		};

		scenario.next_tx(@alice);
		{
			let meet = scenario.take_from_sender<Meet>();
			transfer::public_freeze_object(meet);
		};

		scenario.next_tx(@alice);
		{
			// mint and transfer attendance should Fail
			let mut meet = scenario.take_from_sender<Meet>();
			mint_and_transfer(
				&mut meet,
				b"Bob".to_string(),
				b"description".to_string(),
				b"image_url".to_string(),
				1,
				@bob,
				scenario.ctx(),
			);
			scenario.return_to_sender(meet);
		};

		scenario.end();
	}
}
