local base64 = require "st.base64"
local test = require "integration_test"
local data_types = require "st.zigbee.data_types"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"
local capabilities = require "st.capabilities"

local SMARTSENSE_PROFILE_ID = 0xFC01
local MFG_CODE = 0x110A
local SMARTSENSE_MULTI_CLUSTER = 0xFC03
local SMARTSENSE_MULTI_ACC_CMD = 0x00
local SMARTSENSE_MULTI_XYZ_CMD = 0x05
local SMARTSENSE_MULTI_STATUS_CMD = 0x07
local SMARTSENSE_MULTI_STATUS_REPORT_CMD = 0x09
local FRAME_CTRL = 0x1D
local ENDPOINT = 0x01

local mock_device = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition("smartsense-multi.yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        server_clusters = {SMARTSENSE_MULTI_CLUSTER}
      }
    }
  }
)

zigbee_test_utils.prepare_zigbee_env_info()

local function test_init()
  test.mock_device.add_test_device(mock_device)
end

test.set_test_init_function(test_init)

local build_acceleration_message = function(device, payload)
  local message = zigbee_test_utils.build_custom_command_id(
          device,
          SMARTSENSE_MULTI_CLUSTER,
          SMARTSENSE_MULTI_ACC_CMD,
          MFG_CODE,
          payload,
          ENDPOINT
  )

  message.body.zcl_header.frame_ctrl.value = FRAME_CTRL
  message.address_header.profile.value = SMARTSENSE_PROFILE_ID

  return message
end

local build_multi_status_message = function(device, payload)
  local message = zigbee_test_utils.build_custom_command_id(
          device,
          SMARTSENSE_MULTI_CLUSTER,
          SMARTSENSE_MULTI_STATUS_CMD,
          MFG_CODE,
          payload,
          ENDPOINT
  )

  message.body.zcl_header.frame_ctrl.value = FRAME_CTRL
  message.address_header.profile.value = SMARTSENSE_PROFILE_ID

  return message
end

local build_multi_status_report_message = function(device, payload)
  local message = zigbee_test_utils.build_custom_command_id(
          device,
          SMARTSENSE_MULTI_CLUSTER,
          SMARTSENSE_MULTI_STATUS_REPORT_CMD,
          MFG_CODE,
          payload,
          ENDPOINT
  )

  message.body.zcl_header.frame_ctrl.value = FRAME_CTRL
  message.address_header.profile.value = SMARTSENSE_PROFILE_ID

  return message
end

local build_three_axis_report_message = function(device, payload)
  local message = zigbee_test_utils.build_custom_command_id(
          device,
          SMARTSENSE_MULTI_CLUSTER,
          SMARTSENSE_MULTI_XYZ_CMD,
          MFG_CODE,
          payload,
          ENDPOINT
  )

  message.body.zcl_header.frame_ctrl.value = FRAME_CTRL
  message.address_header.profile.value = SMARTSENSE_PROFILE_ID

  return message
end

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x00 should be handled as: Acceleration - active",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_acceleration_message(mock_device, "\x01")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.active()))
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x07 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - open, battery(60%)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_multi_status_message(mock_device, "\xFF\x4B")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.active()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.open()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x07 should be handled as: Temperature (25.5 C), Acceleration - inactive, Contact - open, battery(60%)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_multi_status_message(mock_device, "\xFF\x4A")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.inactive()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.open()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x07 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - closed, battery(60%)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_multi_status_message(mock_device, "\xFF\x49")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.active()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
    end
)

test.register_coroutine_test(
  "Report from cluster 0xFC03, command 0x07 should be handled as: Temperature (25.5 C), Acceleration - inactive, Contact - closed, battery(60%)",
  function()
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      build_multi_status_message(mock_device, "\xFF\x48")
    })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.inactive()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
  end
)

test.register_coroutine_test(
  "Report from cluster 0xFC03, command 0x00 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - open, battery(60%)",
  function()
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      build_multi_status_report_message(mock_device, "\xFF\x03\x48")
    })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.active()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.open()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
  end
)

test.register_coroutine_test(
  "Report from cluster 0xFC03, command 0x00 should be handled as: Temperature (25.5 C), Acceleration - inactive, Contact - open, battery(60%)",
  function()
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      build_multi_status_report_message(mock_device, "\xFF\x02\x48")
    })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.inactive()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.open()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
  end
)

test.register_coroutine_test(
  "Report from cluster 0xFC03, command 0x00 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - closed, battery(60%)",
  function()
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      build_multi_status_report_message(mock_device, "\xFF\x01\x48")
    })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.active()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed()))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
  end
)

test.register_coroutine_test(
    "KK - Report from cluster 0xFC03, command 0x00 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - closed, battery(97%)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_multi_status_report_message(mock_device, "\x88\x00\x74")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 13.60, unit = "C" })))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.inactive()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(97)))
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x00 should be handled as: Temperature (25.5 C), Acceleration - active, Contact - closed, battery(60%)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_multi_status_report_message(mock_device, "\xFF\x00\x48")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.5, unit = "C" })))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.accelerationSensor.acceleration.inactive()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed()))
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.battery.battery(60)))
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x05 should be handled as: threeAxis(1050, -3, 9)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_three_axis_report_message(mock_device, "\x1A\x04\xFD\xFF\x09\x00")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.threeAxis.threeAxis({1050, -3, 9})) )
    end
)

test.register_coroutine_test(
    "Report from cluster 0xFC03, command 0x05 should be handled as: threeAxis(1123,-130,-24)",
    function()
      test.socket.zigbee:__queue_receive({
        mock_device.id,
        build_three_axis_report_message(mock_device, "\x63\x04\x7E\xFF\xE8\xFF")
      })
      test.socket.capability:__set_channel_ordering("relaxed")
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.threeAxis.threeAxis({1123, -130, -24})) )
    end
)

test.run_registered_tests()