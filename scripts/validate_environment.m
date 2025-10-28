function validate_environment()
    try
        % Basic math test
        assert(2 + 2 == 4, 'Math test failed');

        % Load params test
        params = define_system_parameters();
        assert(params.shaft.length > 0, 'Shaft definition failed');

        % Save/delete file test
        save('env_test.mat', 'params');
        delete('env_test.mat');

        fprintf('🎉 ENVIRONMENT VALIDATION PASSED!\n');
    catch ME
        fprintf('❌ ENVIRONMENT VALIDATION FAILED:\n%s\n', ME.message);
    end
end