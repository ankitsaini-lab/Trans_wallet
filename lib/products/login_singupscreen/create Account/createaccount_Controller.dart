import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/textfieldwidget.dart';

class CreateaccountController extends GetxController {
  var title = 'Select'.obs;
  var firstName = ''.obs;
  var midName = ''.obs;
  var lastName = ''.obs;
  var gender = ''.obs;
  var dob = ''.obs;

  var hasCode = true.obs; // The screenshot shows this checked by default

  var kitNumber = ''.obs;
  var cardNumber = ''.obs;

  var email = ''.obs;
  var address1 = ''.obs;
  var address2 = ''.obs;
  var pincode = ''.obs;
  var city = ''.obs;
  var state = ''.obs;
  var country = 'India'.obs;

  final pincodeController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final isFetchingPincode = false.obs;

  var step = 1.obs;

  @override
  void onInit() {
    super.onInit();
    final box = GetStorage();
    final savedTitle = box.read('reg_title') ?? box.read('title');
    if (savedTitle != null && savedTitle.toString().isNotEmpty) {
      final clean = savedTitle.toString().replaceAll('.', '').trim();
      if (clean.isNotEmpty && clean != 'Select') {
        title.value = clean;
      }
    }
  }

  @override
  void onClose() {
    pincodeController.dispose();
    stateController.dispose();
    cityController.dispose();
    super.onClose();
  }

  Future<void> fetchPincodeDetails(String pinCodeVal) async {
    final cleanPin = pinCodeVal.trim();
    if (cleanPin.length != 6) return;

    try {
      isFetchingPincode.value = true;
      pincodeError.value = '';

      final res = await ApiService.to.fetchPincodeDetails(cleanPin);

      if (res != null &&
          (res['apiSuccess'] == true || res['pincode'] != null)) {
        final fetchedState = (res['state'] ?? '').toString().trim();
        final fetchedDistrict = (res['district'] ?? res['city'] ?? '')
            .toString()
            .trim();

        if (fetchedState.isNotEmpty) {
          state.value = fetchedState;
          stateController.text = fetchedState;
          stateError.value = '';
        }
        if (fetchedDistrict.isNotEmpty) {
          city.value = fetchedDistrict;
          cityController.text = fetchedDistrict;
          cityError.value = '';
        }
      } else {
        pincodeError.value = "Invalid pincode or details not found";
      }
    } catch (e) {
      pincodeError.value = "Failed to fetch pincode details";
    } finally {
      isFetchingPincode.value = false;
    }
  }

  final titleError = ''.obs;
  final firstNameError = ''.obs;
  final middleNameError = ''.obs;
  final lastNameError = ''.obs;
  final emailError = ''.obs;
  final genderError = ''.obs;
  final dobError = ''.obs;
  final kitError = ''.obs;
  final cardError = ''.obs;

  final address1Error = ''.obs;
  final address2Error = ''.obs;
  final pincodeError = ''.obs;
  final countryError = ''.obs;
  final stateError = ''.obs;
  final cityError = ''.obs;

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  void toggleCode(bool value) {
    hasCode.value = value;
  }

  Widget buildCustomStepper(BuildContext context) {
    return Obx(() {
      int currentStep = step.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background connecting line (grey)
                    Positioned(
                      left: 14,
                      right: 14,
                      child: Container(
                        height: 2.5,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    // Active connecting line (red)
                    Positioned(
                      left: 14,
                      right: 14,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 2.5,
                              width: currentStep == 2
                                  ? constraints.maxWidth
                                  : constraints.maxWidth * 0.5,
                              color: primaryRed,
                            );
                          },
                        ),
                      ),
                    ),
                    // Step 1 Circle
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: currentStep == 2
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : const Text(
                                  "1",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Step 2 Circle
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: currentStep == 2
                              ? primaryRed
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "2",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: currentStep == 2
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Details",
                    style: TextStyle(
                      fontSize: context.responsive(12),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Address",
                    style: TextStyle(
                      fontSize: context.responsive(12),
                      fontWeight: currentStep == 2
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: currentStep == 2 ? Colors.black : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required RxString errorText,
    TextEditingController? controller,
    List<TextInputFormatter>? inpputofrmater,
    TextInputType? keyboardtype,
    bool enabled = true,
  }) {
    return Obx(
      () => CustomTextField(
        label: label,
        controller: controller,
        hintText: hint,
        onChanged: onChanged,
        errorText: errorText.value.isEmpty ? null : errorText.value,
        inputFormatters: inpputofrmater,
        keyboardType: keyboardtype ?? TextInputType.text,
        enabled: enabled,
      ),
    );
  }

  void nextStep() {
    titleError.value = title.value == 'Select' ? "Title is required" : "";
    firstNameError.value = firstName.value.isEmpty
        ? "First Name is required"
        : "";
    middleNameError.value = ""; // Middle Name is optional
    lastNameError.value = lastName.value.isEmpty ? "Last Name is required" : "";

    emailError.value = email.value.isEmpty
        ? "Email is required"
        : !_isValidEmail(email.value)
        ? "Enter a valid email address"
        : "";

    genderError.value = gender.value.isEmpty ? "Gender is required" : "";

    if (dob.value.isEmpty) {
      dobError.value = "Date of birth is required";
    } else {
      dobError.value = "";
    }

    if (hasCode.value) {
      kitError.value = kitNumber.value.isEmpty ? "Kit Number is required" : "";
      cardError.value = cardNumber.value.isEmpty
          ? "Card Number is required"
          : "";
    } else {
      kitError.value = "";
      cardError.value = "";
    }

    bool hasError =
        titleError.value.isNotEmpty ||
        firstNameError.value.isNotEmpty ||
        lastNameError.value.isNotEmpty ||
        emailError.value.isNotEmpty ||
        genderError.value.isNotEmpty ||
        dobError.value.isNotEmpty ||
        kitError.value.isNotEmpty ||
        cardError.value.isNotEmpty;

    if (hasError) {
      AppSnackbar.error("Please fill all the required fields correctly.");
      return;
    }

    final box = GetStorage();
    final cleanTitle = title.value.replaceAll('.', '').trim();
    final titleToSave = (cleanTitle == 'Select' || cleanTitle.isEmpty)
        ? 'Mr'
        : cleanTitle;
    box.write('reg_title', titleToSave);
    box.write('title', titleToSave);
    box.write('reg_firstName', firstName.value.trim());
    box.write('reg_middleName', midName.value.trim());
    box.write('reg_lastName', lastName.value.trim());
    box.write('reg_gender', gender.value.trim());
    box.write('reg_email', email.value.trim());
    box.write('reg_dob', dob.value.trim());
    box.write('reg_hasActivationCode', hasCode.value);
    box.write('reg_kitNumber', kitNumber.value.trim());
    box.write('reg_cardNumber', cardNumber.value.trim());

    step.value = 2;
  }

  void previousStep() {
    if (step.value > 1) {
      step.value--;
    }
  }

  Widget _buildGenderBtn(String label, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          gender.value = label;
          genderError.value = "";
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: gender.value == label ? primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: gender.value == label ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: gender.value == label ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStepOene(BuildContext context) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Dropdown
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            "Title",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200, width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: (title.value == 'Select' || title.value.isEmpty)
                        ? null
                        : title.value.replaceAll('.', '').trim(),
                    hint: Text(
                      "Select",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                    ),
                    items: ["Mr", "Ms", "Mrs", "Dr", "Mx"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final selected = (val ?? "Mr").replaceAll('.', '').trim();
                      title.value = selected;
                      titleError.value = "";
                      final box = GetStorage();
                      box.write('reg_title', selected);
                      box.write('title', selected);
                    },
                  ),
                ),
              ),
              if (titleError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    titleError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        buildTextField(
          label: "First Name",
          hint: "Enter First Name",
          errorText: firstNameError,
          onChanged: (v) {
            firstName.value = v;
            if (v.isNotEmpty) firstNameError.value = '';
          },
        ),
        const SizedBox(height: 16),

        buildTextField(
          label: "Middle Name",
          hint: "Enter Middle Name",
          errorText: middleNameError,
          onChanged: (v) {
            midName.value = v;
            if (v.isNotEmpty) middleNameError.value = '';
          },
        ),
        const SizedBox(height: 16),

        buildTextField(
          label: "Last Name",
          hint: "Enter Last Name",
          errorText: lastNameError,
          onChanged: (v) {
            lastName.value = v;
            if (v.isNotEmpty) lastNameError.value = '';
          },
        ),
        const SizedBox(height: 16),

        // Gender Selector
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            "Gender",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    _buildGenderBtn("Male", Icons.male),
                    _buildGenderBtn("Female", Icons.female),
                    _buildGenderBtn("Others", Icons.transgender),
                  ],
                ),
              ),
              if (genderError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    genderError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        buildTextField(
          label: "Email",
          hint: "Enter Email Address",
          errorText: emailError,
          onChanged: (v) {
            email.value = v;
            if (v.isNotEmpty && !_isValidEmail(v)) {
              emailError.value = "Enter a valid email address";
            } else {
              emailError.value = "";
            }
          },
          inpputofrmater: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@._\-+]")),
          ],
        ),
        const SizedBox(height: 16),

        // Date of Birth
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            "Date of Birth",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final today = DateTime.now();
                  final maxAdultDate = DateTime(
                    today.year - 18,
                    today.month,
                    today.day,
                  );
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: maxAdultDate,
                    firstDate: DateTime(1700),
                    lastDate: maxAdultDate,
                  );
                  if (picked != null) {
                    dob.value = "${picked.day}/${picked.month}/${picked.year}";
                    dobError.value = "";
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dob.value.isEmpty ? "Select Date Of Birth" : dob.value,
                        style: TextStyle(
                          color: dob.value.isEmpty
                              ? Colors.grey.shade400
                              : Colors.black,
                          fontWeight: dob.value.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              if (dobError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    dobError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Obx(
          () => Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  activeColor: primaryRed,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  value: hasCode.value,
                  onChanged: (v) => toggleCode(v ?? false),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => toggleCode(true),
                child: const Text(
                  "I have an activation code",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Obx(
          () => hasCode.value
              ? buildTextField(
                  label: "Kit Number",
                  hint: "KIT-000123",
                  enabled: hasCode.value,
                  errorText: kitError,
                  onChanged: (v) {
                    kitNumber.value = v;
                    if (v.isNotEmpty) kitError.value = '';
                  },
                )
              : const SizedBox.shrink(),
        ),

        Obx(
          () => hasCode.value
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
        ),

        Obx(
          () => hasCode.value
              ? buildTextField(
                  label: "Card Number",
                  hint: "Last 4 Digit Of Card",
                  enabled: hasCode.value,
                  errorText: cardError,
                  keyboardtype: TextInputType.number,
                  inpputofrmater: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (v) {
                    cardNumber.value = v;
                    if (v.isNotEmpty) cardError.value = '';
                  },
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 30),

        // Next Step Button
        GestureDetector(
          onTap: nextStep,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                "Next Step",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget buildStepTwo(BuildContext context) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        height14,
        Text(
          "Permanent Address",
          style: TextStyle(
            fontSize: context.responsive(16),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        height14,
        buildTextField(
          label: "Address Line 1",
          hint: "Enter Address",
          errorText: address1Error,
          onChanged: (v) {
            address1.value = v;
            if (v.isNotEmpty) address1Error.value = '';
          },
        ),
        const SizedBox(height: 16),

        buildTextField(
          label: "Address Line 2 (Optional)",
          hint: "Enter Address",
          errorText: address2Error,
          onChanged: (v) {
            address2.value = v;
            if (v.isNotEmpty) address2Error.value = '';
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildTextField(
                label: "Pincode",
                hint: "Enter Pincode",
                controller: pincodeController,
                errorText: pincodeError,
                keyboardtype: TextInputType.number,
                inpputofrmater: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (v) {
                  pincode.value = v;
                  if (v.isNotEmpty) pincodeError.value = '';
                  if (v.length == 6) {
                    fetchPincodeDetails(v);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                label: "Country",
                hint: "India",
                enabled: false,
                errorText: countryError,
                onChanged: (v) {},
              ),
            ),
          ],
        ),
        Obx(
          () => isFetchingPincode.value
              ? const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryRed,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Fetching location details...",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildTextField(
                label: "State",
                hint: "Enter State",
                controller: stateController,
                errorText: stateError,
                onChanged: (v) {
                  state.value = v;
                  if (v.isNotEmpty) stateError.value = '';
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                label: "City",
                hint: "Enter City/District",
                controller: cityController,
                errorText: cityError,
                onChanged: (v) {
                  city.value = v;
                  if (v.isNotEmpty) cityError.value = '';
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Proceed Button
        GestureDetector(
          onTap: () {
            address1Error.value = address1.value.isEmpty
                ? "Address Line 1 is required"
                : "";
            pincodeError.value = pincode.value.isEmpty
                ? "Pincode is required"
                : "";
            stateError.value = state.value.isEmpty ? "State is required" : "";
            cityError.value = city.value.isEmpty ? "City is required" : "";

            bool hasError =
                address1Error.value.isNotEmpty ||
                pincodeError.value.isNotEmpty ||
                stateError.value.isNotEmpty ||
                cityError.value.isNotEmpty;
            if (hasError) {
              AppSnackbar.error(
                "Please fill all the required fields correctly.",
              );
              return;
            }

            final box = GetStorage();
            final cleanTitle = title.value.replaceAll('.', '').trim();
            final titleToSave = (cleanTitle == 'Select' || cleanTitle.isEmpty)
                ? 'Mr'
                : cleanTitle;
            box.write('reg_title', titleToSave);
            box.write('title', titleToSave);
            box.write('reg_firstName', firstName.value.trim());
            box.write('reg_middleName', midName.value.trim());
            box.write('reg_lastName', lastName.value.trim());
            box.write('reg_gender', gender.value.trim());
            box.write('reg_email', email.value.trim());
            box.write('reg_dob', dob.value.trim());
            box.write('reg_hasActivationCode', hasCode.value);
            box.write('reg_kitNumber', kitNumber.value.trim());
            box.write('reg_addressLine1', address1.value.trim());
            box.write('reg_addressLine2', address2.value.trim());
            box.write('reg_pincode', pincode.value.trim());
            box.write('reg_country', country.value.trim());
            box.write('reg_state', state.value.trim());
            box.write('reg_city', city.value.trim());

            final regToken =
                (box.read('registrationToken') ??
                        box.read('registration_token') ??
                        box.read('auth_token') ??
                        box.read('token') ??
                        '')
                    .toString()
                    .trim();
            Get.toNamed(
              '/minkyc_view',
              arguments: {'title': titleToSave, 'registrationToken': regToken},
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                "Proceed to Min KYC",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Go to Previous Step Button
        GestureDetector(
          onTap: previousStep,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.keyboard_return_rounded,
                  size: 20,
                  color: Colors.black87,
                ),
                SizedBox(width: 8),
                Text(
                  "Go to Previous Step",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        height40,
      ],
    );
  }
}
