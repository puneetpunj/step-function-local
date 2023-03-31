STATE_MACHINE_NAME=backup
STATE_MACHINE_DEFINITION_FILE=file://statemachine/${STATE_MACHINE_NAME}.json
STATE_MACHINE_ARN=arn:aws:states:ap-southeast-2:123456789013:stateMachine:${STATE_MACHINE_NAME}
STATE_MACHINE_EXECUTION_ARN=arn:aws:states:ap-southeast-2:123456789013:execution:${STATE_MACHINE_NAME}

run:
	docker compose up -d --force-recreate 

create:
	aws stepfunctions create-state-machine \
		--endpoint-url http://localhost:8083 \
		--definition  ${STATE_MACHINE_DEFINITION_FILE}\
		--name ${STATE_MACHINE_NAME} \
		--role-arn "arn:aws:iam::123456789012:role/DummyRole" \
		--no-cli-pager

ecs_services_running:
	aws stepfunctions start-execution \
		--endpoint http://localhost:8083 \
		--name ECSServicesAreRunningExecution \
		--state-machine ${STATE_MACHINE_ARN}#ECSServicesAreRunning \
		--input file://events/sfn_valid_input.json \
		--no-cli-pager

ecs_services_stopped:
	aws stepfunctions start-execution \
		--endpoint http://localhost:8083 \
		--name ECSServicesAreStoppedExecution \
		--state-machine ${STATE_MACHINE_ARN}#ECSServicesAreStopped \
		--input file://events/sfn_valid_input.json \
		--no-cli-pager

scale_in_service_lambda_error:
	aws stepfunctions start-execution \
		--endpoint http://localhost:8083 \
		--name ScaleInServiceErrorExecution \
		--state-machine ${STATE_MACHINE_ARN}#ScaleInServiceLambdaError \
		--input file://events/sfn_valid_input.json \
		--no-cli-pager

check_status_lambda_error:
	aws stepfunctions start-execution \
		--endpoint http://localhost:8083 \
		--name CheckStatusLambdaErrorExecution \
		--state-machine ${STATE_MACHINE_ARN}#CheckStatusLambdaError \
		--input file://events/sfn_valid_input.json \
		--no-cli-pager

invalid_input:
	aws stepfunctions start-execution \
		--endpoint http://localhost:8083 \
		--name InvalidInputExecution \
		--state-machine ${STATE_MACHINE_ARN}#InvalidInput \
		--input file://events/sfn_invalid_input.json \
		--no-cli-pager

invalid_input_test:
	aws stepfunctions get-execution-history \
		--endpoint http://localhost:8083 \
		--execution-arn ${STATE_MACHINE_EXECUTION_ARN}:InvalidInputExecution \
		--query 'events[?type==`ExecutionFailed`]' \
		--no-cli-pager

ecs_services_running_test:
	aws stepfunctions get-execution-history \
		--endpoint http://localhost:8083 \
		--execution-arn ${STATE_MACHINE_EXECUTION_ARN}:ECSServicesAreRunningExecution \
		--query 'events[?type==`WaitStateEntered`]' \
		--no-cli-pager

ecs_services_stopped_test:
	aws stepfunctions get-execution-history \
		--endpoint http://localhost:8083 \
		--execution-arn ${STATE_MACHINE_EXECUTION_ARN}:ECSServicesAreStoppedExecution \
		--query 'events[?type==`ExecutionSucceeded`]' \
		--no-cli-pager

scale_in_service_lambda_error_test:
	aws stepfunctions get-execution-history \
		--endpoint http://localhost:8083 \
		--execution-arn ${STATE_MACHINE_EXECUTION_ARN}:ScaleInServiceErrorExecution \
		--query 'events[?type==`TaskFailed`]' \
		--no-cli-pager

check_status_lambda_error_test:
	aws stepfunctions get-execution-history \
		--endpoint http://localhost:8083 \
		--execution-arn ${STATE_MACHINE_EXECUTION_ARN}:CheckStatusLambdaErrorExecution \
		--query 'events[?type==`TaskFailed`]' \
		--no-cli-pager

setup_all: ecs_services_running ecs_services_stopped scale_in_service_lambda_error check_status_lambda_error invalid_input
	
test_all: ecs_services_running_test ecs_services_stopped_test scale_in_service_lambda_error_test check_status_lambda_error_test invalid_input_test

describe_sf:
	aws stepfunctions describe-state-machine \
	--endpoint http://localhost:8083 \
	--state-machine-arn ${STATE_MACHINE_ARN} \
	--no-cli-pager
